# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module DimensionElements
        module Prep
          extend self
          
          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__dimension_elements,
                destination: :prep__dimension_elements
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Delete::Fields,
                fields: %i[
                           displayed showelementname showdescription position showsecondaryunit
                          ]
              transform Tms::Transforms::DeleteNoValueTypes, field: :element
              transform Rename::Field, from: :element, to: :origelement
              transform Replace::FieldValueWithStaticMapping,
                source: :origelement,
                target: :element,
                mapping: Tms::DimensionElements.element_mapping,
                fallback_val: 'NEEDS MAPPING',
                delete_source: false
            end
          end
        end
      end
    end
  end
end
