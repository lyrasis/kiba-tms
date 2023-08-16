# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Places
        module CleanedExploded
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :places__cleaned_unique,
                destination: :places__cleaned_exploded
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::Places::ExplodeValues,
                referencefields: %i[clean_combined norm_combineds occurrences]
            end
          end
        end
      end
    end
  end
end
