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
            base << :prep__object_statuses if Tms::ObjectStatuses.used?
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

              if Tms::Departments.used?
                transform Merge::MultiRowLookup,
                  keycolumn: :departmentid,
                  lookup: prep__departments,
                  fieldmap: {
                    config.department_target => :department
                  },
                  delim: Tms.delim
                if config.department_coll_prefix
                  transform Prepend::ToFieldValue,
                    field: config.department_target,
                    value: config.department_coll_prefix
                end
              end
              transform Delete::Fields, fields: :departmentid

              if Tms::ObjectStatuses.used?
                transform Merge::MultiRowLookup,
                  keycolumn: :objectstatusid,
                  lookup: prep__object_statuses,
                  fieldmap: {
                    main_objectstatus: :objectstatus
                  },
                  delim: Tms.delim
              end
              transform Delete::Fields, fields: :objectstatusid

              unless config.field_cleaners.empty?
                config.field_cleaners.each { |cleaner| transform cleaner }
              end
            end
          end
        end
      end
    end
  end
end
