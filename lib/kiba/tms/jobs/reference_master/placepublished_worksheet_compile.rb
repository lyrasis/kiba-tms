# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ReferenceMaster
        module PlacepublishedWorksheetCompile
          module_function

          def job
            return unless config.placepublished_done
            return if config.placepublished_worksheets.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: config.placepublished_worksheet_jobs,
                destination: :reference_master__placepublished_worksheet_compile
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
