# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ValuationControl
        module FromAccessionLot
          module_function

          def job
            return unless Tms::AccessionLot.used?
            return unless Tms::AccessionLot.has_valuations

            approaches = Tms::ObjAccession.processing_approaches
            return unless approaches.any?(:linkedlot)

            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :accession_lot__valuation_prep,
                destination: :valuation_control__from_accession_lot
              },
              transformer: xforms,
              helper: config.multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields, fields: :acquisitionlotid
            end
          end
        end
      end
    end
  end
end
