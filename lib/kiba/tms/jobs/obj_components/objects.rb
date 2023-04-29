# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjComponents
        module Objects
          module_function

          def job
            return unless config.used?
            return unless config.actual_components

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_components__actual_components,
                destination: :obj_components__objects,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            if merges_dimensions?
              base << :dim_item_elem_xrefs_for__obj_components
            end
            base
          end

          def merges_dimensions?
            Tms::DimItemElemXrefs.used? &&
              Tms::DimItemElemXrefs.for?("ObjComponents")
          end

          def xforms
            bind = binding
            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Delete::FieldsExcept,
                fields: %i[componentid componentnumber objcompstatus active
                           physdesc storagecomments installcomments compcount
                           title te_comment]
              transform Rename::Fields, fieldmap: {
                componentnumber: :objectnumber,
                physdesc: :briefdescription,
                compcount: :numberofobjects
              }
              transform Merge::ConstantValue,
                target: :cataloglevel,
                value: "component"

              unless config.inventorystatus_fields.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: config.inventorystatus_fields,
                  target: :inventorystatus,
                  sep: Tms.delim,
                  delete_sources: true
              end

              unless config.comment_fields.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: config.comment_fields,
                  target: :comment,
                  sep: Tms.delim,
                  delete_sources: true
              end

              if bind.receiver.send(:merges_dimensions?)
                transform Merge::MultiRowLookup,
                  lookup: dim_item_elem_xrefs_for__obj_components,
                  keycolumn: :componentid,
                  fieldmap: {
                    dimensionsummary: :displaydimensions,
                    valuedate: :valuedate,
                    measuredpartnote: :description,
                    measuredpart: :element,
                    measurementunit: :measurementunit,
                    value: :value,
                    dimension: :dimension
                  },
                  sorter: Lookup::RowSorter.new(on: :rank, as: :to_i)
                transform Delete::DelimiterOnlyFieldValues,
                  fields: %i[valuedate measurementunit value dimension]
              end
            end
          end
        end
      end
    end
  end
end
