# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConceptAssociated
        module Ingest
          module_function

          def job
            return if config.compile_sources.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :concept_associated__lookup,
                destination: :concept_associated__ingest
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Deduplicate::Table,
                field: :use
              transform Delete::Fields,
                fields: %i[termused termid candidate approved]
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
