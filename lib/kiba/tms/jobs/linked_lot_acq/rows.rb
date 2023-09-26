# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LinkedLotAcq
        module Rows
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :linked_lot_acq__obj_rows,
                destination: :linked_lot_acq__rows
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Deduplicate::Table, field: :acquisitionlotid

              transform Tms::Transforms::AddIncrementingValue,
                prefix: "linkedlot"
              transform Rename::Field,
                from: :lotnumber,
                to: :acquisitionreferencenumber
            end
          end
        end
      end
    end
  end
end
