# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ChronologyEvent
        module Ingest
          module_function

          def job
            return if config.compile_sources.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :chronology_event__lookup,
                destination: :chronology_event__ingest
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Deduplicate::Table,
                field: :norm,
                delete_field: true
              transform Delete::Fields,
                fields: %i[termused normduplicate termduplicate termid
                  candidate approved]
              transform Rename::Field,
                from: :use,
                to: :termdisplayname
              transform Delete::EmptyFields

              transform Tms.final_data_cleaner if Tms.final_data_cleaner
            end
          end
        end
      end
    end
  end
end
