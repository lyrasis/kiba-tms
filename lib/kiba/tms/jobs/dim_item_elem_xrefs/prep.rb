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
            base << :prep__dimensions if Tms::Dimensions.used?
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

              unless Tms::Dimensions.migrate_secondary_unit_vals
                transform do |row|
                  display = row[:displaydimensions]
                  row[:displaydimensions] = display.sub(/ \(.*\)$/, "")
                  row
                end
              end

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

              if Tms::Dimensions.used?
                transform Merge::MultiRowLookup,
                  lookup: prep__dimensions,
                  keycolumn: :dimitemelemxrefid,
                  fieldmap: {
                    measurementunit: :measurementunit,
                    value: :value,
                    dimension: :dimension
                  },
                  sorter: Lookup::RowSorter.new(on: :rank, as: :to_i),
                  delim: Tms.sgdelim
              end
              transform Delete::Fields, fields: :dimitemelemxrefid

              transform do |row|
                row[:valuedate] = nil
                dimdate = row[:dimensiondate]
                next row if dimdate.blank?

                val = row[:value]
                next row if val.blank?

                vals = val.split(Tms.sgdelim)
                dimdates = []
                vals.length.times { dimdates << dimdate }
                row[:valuedate] = dimdates.join(Tms.sgdelim)
                row
              end
              transform Delete::Fields, fields: :dimensiondate
            end
          end
        end
      end
    end
  end
end
