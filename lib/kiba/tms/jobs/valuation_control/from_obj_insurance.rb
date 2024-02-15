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
                source: :prep__obj_insurance,
                destination: :valuation_control__from_obj_insurance
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform do |row|
                row[:padnote] = nil
                val = row[:valueisodate]
                next row if val.blank?

                prefix = "TMS->CS migration note: "
                case val
                when /^\d{4}-\d{2}-\d{2}$/
                  next row
                when /^\d{4}-\d{2}$/
                  row[:valueisodate] = "#{val}-01"
                  row[:padnote] = "#{prefix}Date day value padded to 01"
                when /^\d{4}$/
                  row[:valueisodate] = "#{val}-01-01"
                  row[:padnote] = "#{prefix}Date month/day values padded to "\
                    "01-01"
                end
                row
              end

              if Tms::ValuationPurposes.used?
                transform Prepend::ToFieldValue,
                  field: :valuationpurpose,
                  value: "Purpose: "
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: %i[valuationpurpose valuenotes padnote],
                  target: :valuenote,
                  delim: Tms.notedelim
              else
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: %i[valuenotes padnote],
                  target: :valuenote,
                  delim: Tms.notedelim
              end
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
