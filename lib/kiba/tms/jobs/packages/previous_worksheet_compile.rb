# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Packages
        module PreviousWorksheetCompile
          module_function

          def job
            return unless config.selection_done
            return if config.provided_worksheets.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: config.provided_worksheet_jobs,
                destination: :packages__previous_worksheet_compile
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Deduplicate::Table,
                field: :packageid,
                delete_field: false
              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
