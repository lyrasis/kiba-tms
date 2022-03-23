# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjComponents
        module_function

        # The logic of this looks flipped, but the field is named "inactive"
        STATUS = {
          '0' => 'active',
          '1' => 'inactive'
        }
        def prep
          xforms = Kiba.job_segment do
            transform Tms::Transforms::DeleteTmsFields
            transform Delete::Fields, fields: %i[sortnumber injurisdiction]
            transform FilterRows::FieldEqualTo, action: :reject, field: :componentid, value: '-1'

            transform Merge::MultiRowLookup,
              lookup: tms__obj_comp_types,
              keycolumn: :componenttype,
              fieldmap: {
                component_type: :objcomptype,
              },
              delim: Tms.delim
            transform Delete::Fields, fields: :componenttype

            transform Merge::MultiRowLookup,
              lookup: tms__obj_comp_statuses,
              keycolumn: :objcompstatusid,
              fieldmap: {
                objcompstatus: :objcompstatus,
              },
              delim: Tms.delim
            transform Delete::Fields, fields: :objcompstatusid

            transform Replace::FieldValueWithStaticMapping,
              source: :inactive,
              target: :active,
              mapping: STATUS
            transform Delete::Fields, fields: :inactive

          end
          
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :tms__obj_components,
              destination: :prep__obj_components,
              lookup: %i[tms__obj_comp_types tms__obj_comp_statuses]
            },
            transformer: xforms
          )
        end

        def with_object_numbers
          xforms = Kiba.job_segment do
            transform Merge::MultiRowLookup,
              lookup: tms__objects,
              keycolumn: :objectid,
              fieldmap: {
                objectnumber: :objectnumber,
              },
              delim: Tms.delim
            transform Tms::Transforms::ObjComponents::FlagTopObjects
          end
          
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :prep__obj_components,
              destination: :obj_components__with_object_numbers,
              lookup: :tms__objects
            },
            transformer: xforms
          )
        end
      end
    end
  end
end
