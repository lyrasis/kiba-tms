# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module DimItemElemXrefs
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__dim_item_elem_xrefs,
                destination: :prep__dim_item_elem_xrefs,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            base << :prep__dimension_elements if Tms::DimensionElements.used?
            base << :prep__dimension_methods if Tms::DimensionMethods.used?
            base
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Tms::Transforms::DeleteTmsFields

              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :displaydimensions

              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
                end

              transform Tms::Transforms::TmsTableNames
              transform Rename::Field, from: :id, to: :recordid

              if Tms::DimensionElements.used?
              transform Merge::MultiRowLookup,
                lookup: prep__dimension_elements,
                keycolumn: :elementid,
                fieldmap: {element: :element}
              end
              transform Delete::Fields, fields: :elementid

              if Tms::DimensionMethods.used?
                transform Merge::MultiRowLookup,
                  lookup: prep__dimension_methods,
                  keycolumn: :methodid,
                  fieldmap: {method: :method}
              end
              transform Delete::Fields, fields: :methodid
            end
          end
        end
      end
    end
  end
end
