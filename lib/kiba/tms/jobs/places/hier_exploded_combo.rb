# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Places
        module HierExplodedCombo
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: %i[
                           places__norm_hier_string
                           places__norm_non_hier_exploded
                           ],
                destination: :places__hier_exploded_combo
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              if Tms.final_data_cleaner
                transform Tms.final_data_cleaner,
                  fields: :value
              end
            end
          end
        end
      end
    end
  end
end
