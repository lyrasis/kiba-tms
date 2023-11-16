# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Objects
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :objects__numbers_cleaned,
                destination: :prep__objects,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            base << :prep__departments if Tms::Departments.used?
            base << :prep__object_levels if Tms::ObjectLevels.used?
            base << :prep__object_statuses if Tms::ObjectStatuses.used?
            base << :prep__object_types if Tms::ObjectTypes.used?
            base.select { |job| Kiba::Extend::Job.output?(job) }
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              transform FilterRows::FieldEqualTo,
                action: :reject,
                field: :objectid,
                value: "-1"

              unless config.field_cleaners.empty?
                config.field_cleaners.each { |cleaner| transform cleaner }
              end

              if config.classifications_merge_xform
                transform config.classifications_merge_xform
              else
                transform Delete::Fields, fields: Tms::Classifications.id_field
              end

              if Tms::Departments.used?
                transform Merge::MultiRowLookup,
                  keycolumn: :departmentid,
                  lookup: prep__departments,
                  fieldmap: {
                    department: :department
                  },
                  delim: Tms.delim
              end
              transform Delete::Fields, fields: :departmentid

              if Tms::ObjectLevels.used?
                transform Merge::MultiRowLookup,
                  lookup: prep__object_levels,
                  keycolumn: Tms::ObjectLevels.id_field,
                  fieldmap: {objectlevel: Tms::ObjectLevels.type_field}
              end
              transform Delete::Fields,
                fields: Tms::ObjectLevels.id_field

              if Tms::ObjectTypes.used?
                transform Merge::MultiRowLookup,
                  lookup: prep__object_types,
                  keycolumn: Tms::ObjectTypes.id_field,
                  fieldmap: {objecttype: Tms::ObjectTypes.type_field}
              end
              transform Delete::Fields,
                fields: Tms::ObjectTypes.id_field

              if Tms::ObjectStatuses.used?
                transform Merge::MultiRowLookup,
                  lookup: prep__object_statuses,
                  keycolumn: Tms::ObjectStatuses.id_field,
                  fieldmap: {main_objectstatus: Tms::ObjectStatuses.type_field}
              end
              transform Delete::Fields,
                fields: Tms::ObjectStatuses.id_field
            end
          end
        end
      end
    end
  end
end
