# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module AccessionLot
        module ValuationPrep
          module_function

          def job
            return unless config.used?
            return unless config.has_valuations

            approaches = Tms::ObjAccession.processing_approaches
            return unless approaches.any?(:linkedlot)

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__accession_lot,
                destination: :accession_lot__valuation_prep
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :accessionvalue
              transform Delete::FieldsExcept,
                fields: %i[acquisitionlotid lotnumber accessionvalue
                  entereddate]
              transform Prepend::ToFieldValue, field: :lotnumber, value: "VC"
              transform Clean::RegexpFindReplaceFieldVals,
                fields: :entereddate,
                find: ' \d{2}.*',
                replace: ""
              transform Rename::Fields, fieldmap: {
                lotnumber: :valuationcontrolrefnumber,
                accessionvalue: :valueamount,
                entereddate: :valuedate
              }
              transform Merge::ConstantValue,
                target: :valuetype,
                value: Tms::ObjAccession.accessionvalue_type
            end
          end
        end
      end
    end
  end
end
