# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Works
        module Lookup
          module_function

          def job
            return if config.compile_sources.empty?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: config.compile_sources,
                destination: :works__lookup
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Cspace::NormalizeForID,
                source: :work,
                target: :norm
              transform Replace::NormWithMostFrequentlyUsedForm,
                normfield: :norm,
                nonnormfield: :work,
                target: :use
              transform Delete::Fields,
                fields: :norm
              transform Deduplicate::Table, field: :work
              transform Clean::EnsureConsistentFields
            end
          end
        end
      end
    end
  end
end
