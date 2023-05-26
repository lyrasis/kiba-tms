# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjGeography
        module AuthHierExplodedCombo
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: %i[
                           obj_geography__auth_norm_hier_string
                           obj_geography__auth_norm_non_hier_exploded
                           ],
                destination: :obj_geography__auth_hier_exploded_combo
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms.final_data_cleaner if Tms.final_data_cleaner
            end
          end
        end
      end
    end
  end
end
