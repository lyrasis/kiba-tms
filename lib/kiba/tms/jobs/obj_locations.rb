# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module_function
        
        def prep
          xforms = Kiba.job_segment do
            transform Tms::Transforms::DeleteTmsFields
            transform Delete::EmptyFields,
              consider_blank: {
                loclevel: '0',
                tempticklerdate: '1900-01-01 00:00:00.000'
              }
            transform Delete::FieldValueMatchingRegexp,
              fields: %i[approver handler requestedby],
              match: '^(\(|\[)[Nn]ot [Ee]ntered(\)|\])$'
            transform Tms::Transforms::ObjLocations::AddFulllocid
          end
          
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :tms__obj_locations,
              destination: :prep__obj_locations
            },
            transformer: xforms
          )
        end

        def not_matching_components
          xforms = Kiba.job_segment do
            transform Merge::MultiRowLookup,
              lookup: tms__obj_components,
              keycolumn: :componentid,
              fieldmap: {
                componentmatch: :componentid,
              },
              delim: Tms.delim
            transform FilterRows::FieldPopulated, action: :reject, field: :componentmatch
            transform Delete::Fields, fields: :componentmatch
          end
          
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :prep__obj_locations,
              destination: :obj_locations__not_matching_components,
              lookup: :tms__obj_components
            },
            transformer: xforms
          )
        end

        def not_matching_locations
          xforms = Kiba.job_segment do
            transform Merge::MultiRowLookup,
              lookup: tms__locations,
              keycolumn: :locationid,
              fieldmap: {
                locationmatch: :locationid,
              },
              delim: Tms.delim
            transform FilterRows::FieldPopulated, action: :reject, field: :locationmatch
            transform Delete::Fields, fields: :locationmatch
          end
          
          Kiba::Extend::Jobs::Job.new(
            files: {
              source: :prep__obj_locations,
              destination: :obj_locations__not_matching_locations,
              lookup: :tms__locations
            },
            transformer: xforms
          )
        end
      end
    end
  end
end
