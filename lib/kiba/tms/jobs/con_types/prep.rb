# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConTypes
        module Prep
          module_function
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__con_types,
                destination: :prep__con_types
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::DeleteNoValueTypes, field: :constituenttype
              transform Rename::Field, from: :constituenttype, to: :orig_constituenttype
              transform Replace::FieldValueWithStaticMapping,
                source: :orig_constituenttype,
                target: :constituenttype,
                mapping: Tms::ConTypes.mappings,
                fallback_val: nil,
                delete_source: false
            end
          end
        end
      end
    end
  end
end
