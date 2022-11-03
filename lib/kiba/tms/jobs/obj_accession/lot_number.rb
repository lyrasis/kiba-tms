# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjAccession
        module LotNumber
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_accession__in_migration,
                destination: :obj_accession__lot_number
              },
              transformer: Tms::LotNumAcq.select_xform
            )
          end
        end
      end
    end
  end
end
