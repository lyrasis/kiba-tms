# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjGeography
        module AuthNormExplodedUniq
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_geography__auth_norm_exploded,
                destination: :obj_geography__auth_norm_exploded_uniq
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              transform Deduplicate::Table,
                field: :key,
                delete_field: false
            end
          end
        end
      end
    end
  end
end
