# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Works
        module Ingest
          module_function

          def job
            return if config.compile_sources.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :works__lookup,
                destination: :works__ingest
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Rename::Field,
                from: :use,
                to: :termdisplayname
              transform Delete::Fields,
                fields: :work
              transform Deduplicate::Table,
                field: :termdisplayname
              transform Tms.final_data_cleaner
            end
          end
        end
      end
    end
  end
end
