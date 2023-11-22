# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConceptEthnographicCulture
        module Ingest
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :concept_ethnographic_culture__lookup,
                destination: :concept_ethnographic_culture__ingest
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Delete::Fields,
                fields: :culture
              transform Deduplicate::Table,
                field: :use
              transform FilterRows::FieldEqualTo,
                action: :reject,
                field: :use,
                value: "%NULLVALUE%"
              transform Rename::Field,
                from: :use,
                to: :termdisplayname
              transform Tms.final_data_cleaner if Tms.final_data_cleaner
            end
          end
        end
      end
    end
  end
end
