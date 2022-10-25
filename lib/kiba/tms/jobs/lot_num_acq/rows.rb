# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LotNumAcq
        module Rows
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :lot_num_acq__obj_rows,
                destination: :lot_num_acq__rows
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Deduplicate::Table,
                field: :acquisitionlot
            end
          end
        end
      end
    end
  end
end
