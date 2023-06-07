# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Places
        module NormExploded
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :places__norm_unique,
                destination: :places__norm_exploded
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Rename::Field,
                from: :occurrences,
                to: :norm_combined_occs
              transform Tms::Transforms::Places::ExplodeValues,
                referencefields: %i[sourcetable norm_combined norm_combined_occs]
            end
          end
        end
      end
    end
  end
end
