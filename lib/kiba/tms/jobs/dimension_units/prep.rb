# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module DimensionUnits
        module Prep
          extend self
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__dimension_units,
                destination: :prep__dimension_units
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Delete::Fields,
                fields: %i[
                           conversionfactor unittypeid unitlabelatend isfractional basedenominator
                           decimalplaces unitcutoff unitspersuperunit unitlabel superunitlabel issuperunit
                          ]
              transform Tms::Transforms::DeleteNoValueTypes, field: :unitname
              transform Rename::Field, from: :unitname, to: :origunit
              transform Replace::FieldValueWithStaticMapping,
                source: :origunit,
                target: :unitname,
                mapping: Tms::DimensionUnits.unit_mapping,
                fallback_val: 'NEEDS MAPPING',
                delete_source: false
            end
          end
        end
      end
    end
  end
end
