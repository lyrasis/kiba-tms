# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ValuationControl
        module FromObjInsurance
          module_function

          def job
            return unless Tms::ObjInsurance.used

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_insurance__migrating,
                destination: :valuation_control__from_obj_insurance
              },
              transformer: [
                config.obj_insurance_pre_xforms,
                xforms
              ].compact
            )
          end

          def xforms
            Kiba.job_segment do
              # if Tms::ValuationPurposes.used?
              #   transform Prepend::ToFieldValue,
              #     field: :valuationpurpose,
              #     value: "Purpose: "
              #   transform CombineValues::FromFieldsWithDelimiter,
              #     sources: %i[valuationpurpose valuenotes padnote],
              #     target: :valuenote,
              #     delim: Tms.notedelim
              # else
              #   transform CombineValues::FromFieldsWithDelimiter,
              #     sources: %i[valuenotes padnote],
              #     target: :valuenote,
              #     delim: Tms.notedelim
              # end
              transform Rename::Fields, fieldmap: {
                value: :valueamount,
                currency: :valuecurrency,
                valueisodate: :valuedate,
                systemvaluetype: :valuetype
              }

              transform Copy::Field,
                from: :objectnumber,
                to: :idbase
            end
          end
        end
      end
    end
  end
end
