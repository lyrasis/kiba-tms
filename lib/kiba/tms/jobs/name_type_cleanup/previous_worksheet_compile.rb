# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameTypeCleanup
        module PreviousWorksheetCompile
          module_function

          def job
            return unless config.done
            return if config.provided_worksheets.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: config.provided_worksheet_jobs,
                destination: :name_type_cleanup__previous_worksheet_compile
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Deduplicate::Table,
                field: :cleanupid,
                delete_field: false
            end
          end
        end
      end
    end
  end
end
