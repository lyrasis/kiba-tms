# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjInsurance
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__obj_insurance,
                destination: :prep__obj_insurance,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = %i[
              names__by_altnameid
              objects__number_lookup
            ]
            base << :prep__valuation_purposes if purposes?
            base << :prep__currencies if currencies?
            base
          end

          def currencies?
            Tms::Currencies.used &&
              Tms.job_output?(:prep__currencies)
          end

          def purposes?
            Tms::ValuationPurposes.used &&
              Tms.job_output?(:prep__valuation_purposes)
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              if config.zero_value_treatment == :drop
                transform Merge::ConstantValueConditional,
                  fieldmap: {dropping: "y"},
                  condition: ->(row) do
                    row[:value] == ".0000"
                  end
              end

              transform Tms.data_cleaner if Tms.data_cleaner

              transform Merge::MultiRowLookup,
                lookup: objects__number_lookup,
                keycolumn: :objectid,
                fieldmap: {objectnumber: :objectnumber}
              transform Delete::Fields, fields: :objectid

              transform Merge::MultiRowLookup,
                lookup: names__by_altnameid,
                keycolumn: :appraiserid,
                fieldmap: {valuesourcepersonlocal: :person},
                conditions: ->(_r, rows) do
                  rows.reject { |row| row[:person].blank? }
                end
              transform Merge::MultiRowLookup,
                lookup: names__by_altnameid,
                keycolumn: :appraiserid,
                fieldmap: {valuesourceorganizationlocal: :org},
                conditions: ->(_r, rows) do
                  rows.reject { |row| row[:org].blank? }
                end
              transform Delete::Fields, fields: :appraiserid

              if bind.receiver.send(:purposes?)
                transform Merge::MultiRowLookup,
                  lookup: prep__valuation_purposes,
                  keycolumn: Tms::ValuationPurposes.id_field,
                  fieldmap: {
                    Tms::ValuationPurposes.type_field =>
                      Tms::ValuationPurposes.type_field
                  }
              end
              transform Delete::Fields, fields: :valuationpurposeid

              if bind.receiver.send(:currencies?)
                transform Merge::MultiRowLookup,
                  lookup: prep__currencies,
                  keycolumn: config.pref_currencyid,
                  fieldmap: {
                    Tms::Currencies.type_field =>
                      Tms::Currencies.type_field
                  }
              end
              transform Delete::Fields, fields: config.pref_currencyid

              transform Replace::FieldValueWithStaticMapping,
                source: :systemvaluetype,
                mapping: config.systemvaluetype_mapping
            end
          end
        end
      end
    end
  end
end
