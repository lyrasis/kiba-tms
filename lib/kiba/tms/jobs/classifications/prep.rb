# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Classifications
        module Prep
          module_function
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__classifications,
                destination: :prep__classifications
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              if Tms::Classifications.omitting_fields?
                transform Delete::Fields, fields: Tms::Classifications.omitted_fields
              end
              transform Tms::Transforms::DeleteNoValueTypes, field: :classification
              transform Rename::Field, from: :classification, to: :orig_classification
              transform Replace::FieldValueWithStaticMapping,
                source: :orig_classification,
                target: :classification,
                mapping: Tms::Classifications.mappings,
                fallback_val: nil,
                delete_source: false
            end
          end
        end
      end
    end
  end
end
