# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module SurveyTypes
        module Prep
          module_function
          
          def job
            return unless config.used?
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__survey_types,
                destination: :prep__survey_types
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding
            Kiba.job_segment do
              config = bind.receiver.send(:config)
              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::DeleteNoValueTypes, field: :surveytype
              transform Rename::Field, from: :surveytype, to: :orig_surveytype
              transform Replace::FieldValueWithStaticMapping,
                source: :orig_surveytype,
                target: :surveytype,
                mapping: config.mappings,
                fallback_val: nil,
                delete_source: false
              transform Tms::Transforms::TmsTableNames
            end
          end
        end
      end
    end
  end
end
