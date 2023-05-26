# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ObjGeography
        module AuthNormNonHierExploded
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :obj_geography__auth_unique_norm,
                destination: :obj_geography__auth_norm_non_hier_exploded
              },
              transformer: xforms
            )
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              transform Delete::Fields,
                fields: config.hierarchy_fields
              transform Tms::Transforms::ObjGeography::ExplodeValues,
                referencefield: :norm_combined
              transform Sort::ByFieldValue,
                field: :value,
                mode: :string
            end
          end
        end
      end
    end
  end
end
