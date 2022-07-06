# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module DimensionTypes
        module Prep
          extend self
          
          def job
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
              transform Delete::Fields,
                fields: %i[
                           unittypeid primaryunitid secondaryunitid system
                          ]
              transform Tms::Transforms::DeleteNoValueTypes, field: :dimensiontype
              transform Rename::Field, from: :dimensiontype, to: :origdimension
              transform Replace::FieldValueWithStaticMapping,
                source: :origdimension,
                target: :dimensiontype,
                mapping: Tms::DimensionTypes.type_mapping,
                fallback_val: 'NEEDS MAPPING',
                delete_source: false
            end
          end
        end
      end
    end
  end
end
