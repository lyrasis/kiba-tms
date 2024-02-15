# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ReferenceMaster
        module PubplaceCleanedLkup
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :reference_master__pubplace_cleaned,
                destination: :reference_master__pubplace_cleaned_lkup
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              # passthrough
            end
          end
        end
      end
    end
  end
end
