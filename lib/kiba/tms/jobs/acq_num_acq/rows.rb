# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AcqNumAcq
        module Rows
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :acq_num_acq__obj_rows,
                destination: :acq_num_acq__rows
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              #complicated
            end
          end
        end
      end
    end
  end
end
