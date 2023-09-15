# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Places
        module InitCleanedTerms
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :places__init_cleaned_lookup,
                destination: :places__init_cleaned_terms
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Deduplicate::Table,
                field: :norm
              transform Delete::Fields,
                fields: :norm_combined
            end
          end
        end
      end
    end
  end
end
