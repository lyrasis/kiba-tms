# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaMaster
        module Prep
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :tms__media_master,
                destination: :prep__media_master,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = []
            base << :prep__departments if merges_depts?
            base
          end

          def merges_depts?
            Tms::Departments.used? && config.fields.any?(:departmentid)
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              mod = bind.receiver
              config = mod.send(:config)

              transform Tms::Transforms::DeleteTmsFields
              if config.omitting_fields?
                transform Delete::Fields, fields: config.omitted_fields
              end

              if mod.send(:merges_depts?)
                fld = Tms::Departments.type_field
                transform Merge::MultiRowLookup,
                  lookup: prep__departments,
                  keycolumn: :departmentid,
                  fieldmap: {fld => fld}
              end

              transform config.publishable_transform

              transform Delete::Fields,
                fields: %i[departmentid
                  publicaccess approvedforweb]
            end
          end
        end
      end
    end
  end
end
