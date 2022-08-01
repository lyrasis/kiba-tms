# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjComponents
        module Objects
          module_function

          def job
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
            base << :text_entries__for_obj_components if Tms::TextEntries.target_tables.any?('ObjComponents')
            base
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[componentid componentnumber objcompstatus active physdesc storagecomments installcomments
                           compcount title]
              transform Rename::Fields, fieldmap: {
                componentnumber: :objectnumber,
                physdesc: :briefdescription,
                compcount: :numberofobjects
              }
              transform Merge::ConstantValue, target: :cataloglevel, value: 'component'
              transform CombineValues::FromFieldsWithDelimiter,
                sources: Tms::ObjComponents.inventorystatus_fields,
                target: :inventorystatus,
                sep: Tms.delim,
                delete_sources: true

              if Tms::TextEntries.target_tables.any?('ObjComponents') && Tms::ObjComponents.text_entries_xform
                Tms::ObjComponents.config.text_entries_lookup = text_entries__for_obj_components
                transform Tms::ObjComponents.text_entries_xform
              end

              unless Tms::ObjComponents.comment_fields.empty?
                transform CombineValues::FromFieldsWithDelimiter,
                  sources: Tms::ObjComponents.comment_fields,
                  target: :comment,
                  sep: Tms.delim,
                  delete_sources: true
              end
            end
          end
        end
      end
    end
  end
end
