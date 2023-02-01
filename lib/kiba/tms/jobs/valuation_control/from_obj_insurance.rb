# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ValuationControl
        module FromObjInsurance
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :prep__obj_insurance,
                destination: :valuation_control__from_obj_insurance
              },
              transformer: xforms,
              helper: config.multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              transform Rename::Fields, fieldmap: {
                value: :valueamount,
                currency: :valuecurrency,
                valueisodate: :valuedate,
                valuenotes: :valuenote,
                systemvaluetype: :valuetype
              }

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[objectnumber valuedate],
                target: :idbase,
                sep: '.',
                delete_sources: false
            end
          end
        end
      end
    end
  end
end
