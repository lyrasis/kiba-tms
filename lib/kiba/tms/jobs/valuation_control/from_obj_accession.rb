# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ValuationControl
        module FromObjAccession
          module_function

          def job
            return unless Tms::ObjAccession.used?
            return unless Tms::ObjAccession.has_objectvalueids

            approaches = Tms::ObjAccession.processing_approaches
            return unless approaches.any?(:linkedlot)

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :accession_lot__valuation_prep,
                destination: :valuation_control__from_accession_lot
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields, fields: :acquisitionlotid

              warn("Need to implement the rest of "\
                   "ValuationControl::FromAccessionLot")
            end
          end
        end
      end
    end
  end
end
