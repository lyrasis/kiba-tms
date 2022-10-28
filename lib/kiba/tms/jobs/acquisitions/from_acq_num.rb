# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Acquisitions
        module FromAcqNum
          module_function

          def job
            return unless Tms::AcqNumAcq.used?

            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :acq_num_acq__prep,
                destination: :acquisitions__from_acq_num
              },
              transformer: xforms,
              helper: config.multisource_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              transform Merge::ConstantValue,
                target: :objaccessiontreatment,
                value: 'acqnumber'
            end
          end
        end
      end
    end
  end
end
