# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Places
        module WorksheetCompile
          module_function

          def job
            return unless config.cleanup_done
            return if config.worksheets.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: config.worksheet_jobs,
                destination: :places__worksheet_compile
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Deduplicate::Table,
                field: :merge_fingerprint,
                delete_field: false
              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
