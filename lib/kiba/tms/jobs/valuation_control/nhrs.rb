# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ValuationControl
        module Nhrs
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :valuation_control__nhrs
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
            end
          end

          def accession_lot?
            true if Tms::AccessionLot.used? &&
              Tms::AccessionLot.has_valuations &&
              Tms::ObjAccession.processing_approaches.any?(:linkedlot)
          end

          def sources
            base = []
            if accession_lot?
              base << :valuation_control__nhr_acq_accession_lot
              base << :valuation_control__nhr_obj_accession_lot
            end
            base
          end
        end
      end
    end
  end
end
