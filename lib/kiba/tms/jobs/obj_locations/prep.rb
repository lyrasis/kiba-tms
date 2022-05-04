# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module Prep
          module_function

          # field is :inactive but I want to map in the affirmative, so logic is switched
          INACTIVE = {
            '0' => 'y',
            '1' => 'n'
          }

          STATUS = {
            '0' => 'pending',
            '1' => 'completed',
            '2' => 'not found',
            '3' => 'found elsewhere',
            '4' => 'cancelled'
          }

          TEMPFLAG = {
            '0' => 'n',
            '1' => 'y'
          }

          TYPE ={
            '1' => 'temporary move',
            '2' => 'move home',
            '3' => 'move to new home',
            '4' => 'inventory',
            '5' => 'spot check',
            '6' => 'random check',
            '7' => 'historical entry',
            '8' => 'scheduled temporary move',
            '10' => 'scheduled move to new home'
          }
         
          def job            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_locations,
                destination: :prep__obj_locations,
                lookup: %i[obj_components__with_object_numbers tms__loc_purposes]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Delete::EmptyFields,
                consider_blank: {
                  dateout: '9999-12-31 00:00:00.000',
                  loclevel: '0',
                  tempticklerdate: '1900-01-01 00:00:00.000'
                }
              transform Delete::FieldValueMatchingRegexp, fields: %i[dateout], match: '^9999-12-31'
              transform FilterRows::FieldEqualTo, action: :reject, field: :objlocationid, value: '-1'
              transform Delete::FieldValueMatchingRegexp,
                fields: %i[approver handler requestedby],
                match: '^(\(|\[)[Nn]ot [Ee]ntered(\)|\])$'
              transform Tms::Transforms::ObjLocations::AddFulllocid
              transform Merge::MultiRowLookup,
                lookup: obj_components__with_object_numbers,
                keycolumn: :componentid,
                fieldmap: {
                  objectnumber: :componentnumber,
                },
                delim: Tms.delim
              transform Merge::MultiRowLookup,
                lookup: tms__loc_purposes,
                keycolumn: :locpurposeid,
                fieldmap: {
                  location_purpose: :locpurpose,
                },
                delim: Tms.delim
              transform Delete::Fields, fields: %i[componentid locpurposeid]

              transform Replace::FieldValueWithStaticMapping, source: :tempflag, target: :is_temp?, mapping: TEMPFLAG
              transform Replace::FieldValueWithStaticMapping, source: :inactive, target: :active?, mapping: INACTIVE
              transform Replace::FieldValueWithStaticMapping, source: :transstatusid, target: :status, mapping: STATUS
              transform Replace::FieldValueWithStaticMapping, source: :transcodeid, target: :type, mapping: TYPE
            end
          end
        end
      end
    end
  end
end
