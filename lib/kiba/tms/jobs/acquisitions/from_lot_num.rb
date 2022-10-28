# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Acquisitions
        module FromLotNum
          module_function

          def job
            return unless Tms::LotNumAcq.used?

            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :lot_num_acq__prep,
                destination: :acquisitions__from_lot_num
              },
              transformer: xforms,
              helper: config.multisource_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
            end
          end
        end
      end
    end
  end
end
