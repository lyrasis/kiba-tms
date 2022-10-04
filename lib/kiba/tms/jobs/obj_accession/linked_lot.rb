# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjAccession
        module LinkedLot
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_accession,
                destination: :obj_accession__linked_lot
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :acquisitionlotid
            end
          end
        end
      end
    end
  end
end
