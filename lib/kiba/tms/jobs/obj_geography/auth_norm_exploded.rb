# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjGeography
        module AuthNormExploded
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_geography__auth_unique_norm,
                destination: :obj_geography__auth_norm_exploded
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::ObjGeography::ExplodeValues,
                referencefield: :norm_combined
             transform Tms.final_data_cleaner if Tms.final_data_cleaner
            end
          end
        end
      end
    end
  end
end