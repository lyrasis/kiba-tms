# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Valuationcontrols
        module FromAccessionLot
          module_function

          def job
            return unless Tms::AccessionLot.used?
            return unless Tms::AccessionLot.has_valuations

            approaches = Tms::ObjAccession.processing_approaches
            return unless approaches.any?(:linkedlot)

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :accession_lot__valuation_prep,
                destination: :valuationcontrols__from_accession_lot
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields, fields: :acquisitionlotid

              raise("Need to implement the rest of "\
                    "Valuationcontrols::FromAccessionLot")

              transform Merge::ConstantValue,
                target: :datasource,
                value: "AccessionLot"
            end
          end
        end
      end
    end
  end
end
