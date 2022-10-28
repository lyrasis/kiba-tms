# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AcqNumAcq
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :acq_num_acq__rows,
                destination: :acq_num_acq__prep
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding
            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Delete::Fields,
                fields: %i[objectvalueid combined]
            end
          end
        end
      end
    end
  end
end
