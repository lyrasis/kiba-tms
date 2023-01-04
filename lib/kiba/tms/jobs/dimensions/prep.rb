# frozen_string_literal: true

require 'bigdecimal'

module Kiba
  module Tms
    module Jobs
      module Dimensions
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__dimensions,
                destination: :prep__dimensions,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            base << :prep__dimension_units if Tms::DimensionUnits.used?
            base << :prep__dimension_types if Tms::DimensionTypes.used?
            base
          end

          # @param val [String]
          # @param conversion [String]
          # @return [String]
          def convert(val, conversion)
            val = BigDecimal(val)
            conv = BigDecimal(conversion)
            (val * conv).to_r
              .round(+3)
              .to_f
              .to_s
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end
              transform FilterRows::FieldEqualTo,
                action: :reject,
                field: :dimension,
                value: '.0000000000'

              if Tms::DimensionUnits.used?
                transform Merge::MultiRowLookup,
                  lookup: prep__dimension_units,
                  keycolumn: :primaryunitid,
                  fieldmap: {
                    primaryunit: Tms::DimensionUnits.type_field,
                    primaryconvert: :conversionfactor
                  }
                if config.migrate_secondary_unit_vals
                  transform Merge::MultiRowLookup,
                    lookup: prep__dimension_units,
                    keycolumn: :secondaryunitid,
                    fieldmap: {
                      secondaryunit: Tms::DimensionUnits.type_field,
                      secondaryconvert: :conversionfactor
                    }
                end
              end
              transform Delete::Fields,
                fields: %i[primaryunitid secondaryunitid]

              transform Rename::Field, from: :dimension, to: :value

              if Tms::DimensionTypes.used?
                transform Merge::MultiRowLookup,
                  lookup: prep__dimension_types,
                  keycolumn: :dimensiontypeid,
                  fieldmap: {dimension: :dimensiontype}
              end
              transform Delete::Fields, fields: :dimensiontypeid

              transform do |row|
                val = row[:value]

                if config.migrate_secondary_unit_vals
                  dim = row[:dimension]
                  row[:dimension] = [dim, dim].join(Tms.sgdelim)
                  row[:value] = [
                    bind.receiver.send(:convert, val, row[:primaryconvert]),
                    bind.receiver.send(:convert, val, row[:secondaryconvert])
                  ].join(Tms.sgdelim)
                  row[:measurementunit] = [
                    row[:primaryunit],
                    row[:secondaryunit]
                  ].join(Tms.sgdelim)
                else
                  row[:value] = bind.receiver.send(
                    :convert, val, row[:primaryconvert]
                  )
                  row[:measurementunit] = row[:primaryunit]
                end

                row
              end

              deletefields = %i[primaryunit primaryconvert]
              if config.migrate_secondary_unit_vals
                deletefields << %i[secondaryunit secondaryconvert]
              end
              transform Delete::Fields,
                fields: deletefields.flatten
            end
          end
        end
      end
    end
  end
end
