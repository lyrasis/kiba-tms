# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Locations
        module PreviousWorksheetCompile
          module_function

          def job
            return unless config.cleanup_done
            return if config.provided_worksheets.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: config.provided_worksheet_jobs,
                destination: :locs__previous_worksheet_compile
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Deduplicate::Table,
                field: :fulllocid,
                delete_field: false
            end
          end
        end
      end
    end
  end
end
