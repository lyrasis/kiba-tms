# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromCanTypematchSeparateNames
          module_function

          def job
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :name_compile__from_can_typematch_separate,
                destination: :name_compile__from_can_typematch_separate_names
              },
              transformer: xforms,
              helper: Kiba::Tms::NameCompile.multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::NameCompile::DeriveSeparateNameFromAlt
            end
          end
        end
      end
    end
  end
end
