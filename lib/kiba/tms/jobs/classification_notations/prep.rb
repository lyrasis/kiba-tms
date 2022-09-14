# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ClassificationNotations
        module Prep
          module_function
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__classification_notations,
                destination: :prep__classification_notations
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              if Tms::ClassificationNotations.omitting_fields?
                transform Delete::Fields, fields: Tms::ClassificationNotations.omitted_fields
              end
            end
          end
        end
      end
    end
  end
end
