# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module Places
        module NormNonHierExploded
          module_function

          def job
            return unless config.used?

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :places__norm_unique,
                destination: :places__norm_non_hier_exploded
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
              transform Tms::Transforms::Places::ExplodeValues,
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
