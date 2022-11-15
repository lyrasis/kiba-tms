# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaFiles
        module Unreferenced
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :media_files__target_report,
                destination: :media_files__unreferenced
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::WithLambda,
                action: :keep,
                lambda: ->(row) do
                  row[:targettable].blank?
                end
            end
          end
        end
      end
    end
  end
end
