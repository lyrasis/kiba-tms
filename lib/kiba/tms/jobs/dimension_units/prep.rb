# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module DimensionUnits
        module Prep
          extend self
          
          def job
            return unless Tms::DimensionUnits.used?
            
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
              if Tms::DimensionUnits.omitting_fields?
                transform Delete::Fields,
                  fields: Tms::DimensionUnits.omitted_fields
              end
              transform Tms::Transforms::DeleteNoValueTypes, field: :unitname
              transform Rename::Field, from: :unitname, to: :origunit
              transform Replace::FieldValueWithStaticMapping,
                source: :origunit,
                target: :unitname,
                mapping: Tms::DimensionUnits.mappings,
                fallback_val: nil,
                delete_source: false
            end
          end
        end
      end
    end
  end
end
