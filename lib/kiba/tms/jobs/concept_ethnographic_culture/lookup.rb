# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ConceptEthnographicCulture
        module Lookup
          module_function

          def job
            return if config.compile_sources.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: config.compile_sources,
                destination: :concept_ethnographic_culture__lookup
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Copy::Field,
                from: :culture,
                to: :culturefin
              if Tms.final_data_cleaner
                transform Tms.final_data_cleaner, fields: :culturefin
              end
              transform Cspace::NormalizeForID,
                source: :culturefin,
                target: :norm
              transform Replace::NormWithMostFrequentlyUsedForm,
                normfield: :norm,
                nonnormfield: :culture,
                target: :use
              transform Deduplicate::Table,
                field: :culture
              transform Delete::Fields,
                fields: %i[norm culturefin]
            end
          end
        end
      end
    end
  end
end
