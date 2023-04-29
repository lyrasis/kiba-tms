# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MediaFiles
        module UnmigratableReport
          module_function

          def job
            return unless config.used?
            return if sources.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: sources,
                destination: :media_files__unmigratable_report
              },
              transformer: xforms
            )
          end

          def sources
            base = []
            unless config.migrate_fileless
              base << :media_files__no_filename
            end
            unless config.migrate_unreferenced
              base << :media_files__unreferenced
            end
            unless config.migrate_unmigratable
              base << :media_files__unmigratable
            end
            base.select { |key| Tms.job_output?(key) }
          end

          def xforms
            Kiba.job_segment do
            end
          end
        end
      end
    end
  end
end
