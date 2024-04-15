# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjInsurance
        module Shape
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_insurance__migrating,
                destination: :obj_insurance__shape
              },
              transformer: [
                config.pre_shape_xforms,
                xforms
              ].compact
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              if Tms::ValuationPurposes.used?
                case config.purpose_treatment
                when :note
                  # Remove valuation purposes that duplicate :systemvaluetype
                  transform do |row|
                    purpose = row[:valuationpurpose]
                    next row if purpose.blank?

                    type = row[:systemvaluetype]
                    next row if type.blank?
                    next row unless purpose.downcase == type.downcase

                    row[:valuationpurpose] = nil
                    row
                  end

                  transform Prepend::ToFieldValue,
                    field: :valuationpurpose,
                    value: "Purpose: "
                else
                  raise("Implement :#{config.purpose_treatment} "\
                        "ObjInsurance.purpose_treatment")
                end
              end

              transform CombineValues::FromFieldsWithDelimiter,
                sources: config.valuenote_sources,
                target: :valuenote,
                delim: Tms.notedelim

              renamemap = {
                value: :valueamount,
                currency: :valuecurrency,
                valueisodate: :valuedate
              }
              renamemap.merge!({config.valuetype_source => :valuetype})
              transform Rename::Fields, fieldmap: renamemap
            end
          end
        end
      end
    end
  end
end
