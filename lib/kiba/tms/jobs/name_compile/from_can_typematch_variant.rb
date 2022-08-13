# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromCanTypematchVariant
          module_function

          def job
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :name_compile__from_can_typematch,
                destination: :name_compile__from_can_typematch_variant
              },
              transformer: xforms,
              helper: Kiba::Tms::NameCompile::multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              transform FilterRows::FieldEqualTo, action: :keep, field: :treatment, value: 'variant'
              transform Tms::Transforms::NameCompile::DeriveVariantName, mode: :alt, from: :altname
            end
          end
        end
      end
    end
  end
end
