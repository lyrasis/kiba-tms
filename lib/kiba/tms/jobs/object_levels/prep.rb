# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjectLevels
        module Prep
          module_function
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__object_levels,
                destination: :prep__object_levels
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::DeleteNoValueTypes, field: :objectlevel
              transform Rename::Field, from: :objectlevel, to: :orig_objectlevel
              transform Replace::FieldValueWithStaticMapping,
                source: :orig_objectlevel,
                target: :objectlevel,
                mapping: Tms::ObjectLevels.mappings,
                fallback_val: nil,
                delete_source: false
            end
          end
        end
      end
    end
  end
end
