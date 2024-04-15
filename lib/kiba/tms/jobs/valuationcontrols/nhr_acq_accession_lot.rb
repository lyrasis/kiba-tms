# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Valuationcontrols
        module NhrAcqAccessionLot
          module_function

          def job
            return unless Tms::AccessionLot.used?
            return unless Tms::AccessionLot.has_valuations

            approaches = Tms::ObjAccession.processing_approaches
            return unless approaches.any?(:linkedlot)

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :accession_lot__valuation_prep,
                destination: :valuationcontrols__nhr_acq_accession_lot
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[valuationcontrolrefnumber]
              transform Rename::Field,
                from: :valuationcontrolrefnumber,
                to: :item2_id
              transform Copy::Field,
                from: :item2_id,
                to: :item1_id
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :item1_id,
                find: "^VC",
                replace: ""
              transform Merge::ConstantValues, constantmap: {
                item1_type: "acquisitions",
                item2_type: "valuationcontrols"
              }
            end
          end
        end
      end
    end
  end
end
