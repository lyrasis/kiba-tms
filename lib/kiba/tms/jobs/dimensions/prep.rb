# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Dimensions
        module Prep
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__dimensions,
                destination: :prep__dimensions,
                lookup: %i[
                           prep__dimension_units
                           prep__dimension_types
                          ]
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Delete::Fields, fields: %i[displayed dimensionid secondaryunitid]
              transform FilterRows::FieldEqualTo, action: :reject, field: :dimension, value: '.0000000000'
              transform Merge::MultiRowLookup,
                lookup: prep__dimension_units,
                keycolumn: :primaryunitid,
                fieldmap: {measurementunit: :unitname}
              transform Delete::Fields, fields: :primaryunitid

              transform Rename::Field, from: :dimension, to: :value
              transform Append::ConvertedValueAndUnit,
                value: :value,
                unit: :measurementunit,
                delim: Tms.sgdelim,
                places: 10

              transform Merge::MultiRowLookup,
                lookup: prep__dimension_types,
                keycolumn: :dimensiontypeid,
                fieldmap: {dimension: :dimensiontype}
              transform Delete::Fields, fields: :dimensiontypeid
            end
          end
        end
      end
    end
  end
end
