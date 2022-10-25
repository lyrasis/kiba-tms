# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module LinkedLotAcq
        module ObjRows
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :prep__obj_accession,
                destination: :linked_lot_acq__obj_rows
              },
              transformer: Tms::LinkedLotAcq.select_xform
            )
          end
        end
      end
    end
  end
end
