# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module DimItemElemXrefs
        module Prep
          module_function

          def job
            warn("\nWARNING: Set up DimensionMethods") if Tms::DimensionMethods.used
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
            base = %i[prep__dimension_elements prep__dimensions]
            # base << :prep__dimension_methods if Tms::DimensionMethods.used
            base
          end
          
          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::DeleteTmsFields
              transform Tms::Transforms::TmsTableNames
              transform Delete::Fields, fields: %i[displayed]
              transform Rename::Field, from: :id, to: :recordid
              transform Merge::MultiRowLookup,
                lookup: prep__dimension_elements,
                keycolumn: :elementid,
                fieldmap: {element: :element}
              transform Delete::Fields, fields: :elementid

              if Tms::DimensionMethods.used
                # transform Merge::MultiRowLookup,
                #   lookup: prep__dimension_methods,
                #   keycolumn: :methodid,
                #   fieldmap: {method: :method}
              end
              transform Delete::Fields, fields: :methodid
            end
          end
        end
      end
    end
  end
end
