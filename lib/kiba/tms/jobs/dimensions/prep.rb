# frozen_string_literal: true

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
                  fieldmap: {measurementunit: :unitname}
              end
              transform Delete::Fields, fields: :primaryunitid

              transform Rename::Field, from: :dimension, to: :value
              transform Append::ConvertedValueAndUnit,
                value: :value,
                unit: :measurementunit,
                delim: Tms.sgdelim,
                places: 10

              if Tms::DimensionTypes.used?
                transform Merge::MultiRowLookup,
                  lookup: prep__dimension_types,
                  keycolumn: :dimensiontypeid,
                  fieldmap: {dimension: :dimensiontype}
              end
              transform Delete::Fields, fields: :dimensiontypeid
            end
          end
        end
      end
    end
  end
end
