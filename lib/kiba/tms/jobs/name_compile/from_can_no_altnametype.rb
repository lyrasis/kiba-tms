# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromCanNoAltnametype
          module_function

          def job
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :con_alt_names__prep_clean,
                destination: :name_compile__from_can_no_altnametype
              },
              transformer: xforms,
              helper: Kiba::Tms::NameCompile.multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              transform Tms::Transforms::NameCompile::SelectCanNoAltnametype

              transform Merge::ConstantValue, target: :termsource,
                value: "TMS ConAltNames.no_altnametype"
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[altnameid mainconid altnameconid],
                target: :constituentid,
                delim: ".",
                delete_sources: true

              transform Tms::Transforms::NameCompile::DeriveVariantName,
                mode: :alt, from: :altname
            end
          end
        end
      end
    end
  end
end
