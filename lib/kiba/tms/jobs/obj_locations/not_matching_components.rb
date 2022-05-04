# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjLocations
        module NotMatchingComponents
          module_function
          
          def job
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
        end
      end
    end
  end
end
