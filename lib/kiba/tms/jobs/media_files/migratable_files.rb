# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaFiles
        module MigratableFiles
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :media_files__migratable,
                destination: :media_files__migratable_files
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::FieldsExcept,
                fields: %i[fullpath filename filesize memorysize]
              transform Deduplicate::Table,
                field: :fullpath,
                delete_field: false
            end
          end
        end
      end
    end
  end
end
