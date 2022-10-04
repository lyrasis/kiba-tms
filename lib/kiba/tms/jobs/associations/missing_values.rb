# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Associations
        module MissingValues
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__associations,
                destination: :associations__missing_values
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::AllFieldsPopulated,
                action: :reject,
                fields: %i[val1 val2]
            end
          end
        end
      end
    end
  end
end
