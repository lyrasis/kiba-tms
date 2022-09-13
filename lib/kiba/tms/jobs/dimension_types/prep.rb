# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module DimensionTypes
        module Prep
          extend self
          
          def job
            return unless Tms::DimensionTypes.used?
            
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__dimension_types,
                destination: :prep__dimension_types
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields

              if Tms::DimensionTypes.omitting_fields?
                transform Delete::Fields,
                  fields: Tms::DimensionTypes.omitted_fields
              end
              transform Tms::Transforms::DeleteNoValueTypes, field: :dimensiontype
              transform Rename::Field, from: :dimensiontype, to: :origdimension
              transform Replace::FieldValueWithStaticMapping,
                source: :origdimension,
                target: :dimensiontype,
                mapping: Tms::DimensionTypes.mappings,
                fallback_val: nil,
                delete_source: false
            end
          end
        end
      end
    end
  end
end
