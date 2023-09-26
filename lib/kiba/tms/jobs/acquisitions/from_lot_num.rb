# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Acquisitions
        module FromLotNum
          module_function

          def job
            return unless Tms::LotNumAcq.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :lot_num_acq__prep,
                destination: :acquisitions__from_lot_num,
                lookup: :acquisitions__ids_final
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Merge::ConstantValue,
                target: :objaccessiontreatment,
                value: "lotnumber"
              transform Delete::Fields,
                fields: :acquisitionreferencenumber
              transform Merge::MultiRowLookup,
                lookup: acquisitions__ids_final,
                keycolumn: :increment,
                fieldmap: {
                  acquisitionreferencenumber: :acquisitionreferencenumber
                }
            end
          end
        end
      end
    end
  end
end
