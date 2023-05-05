# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromCanTypemismatchMainPerson
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :con_alt_names__prep_clean,
                destination: :name_compile__from_can_typemismatch_main_person
              },
              transformer: xforms
            )
          end

          def xforms
            Kiba.job_segment do
              job = :name_compile__from_can_typemismatch_main_person
              treatment = Tms::NameCompile.source_treatment[job]

              transform Tms::Transforms::NameCompile::SelectCanTypemismatchMainPerson

              transform Merge::ConstantValue, target: :termsource,
                value: "TMS ConAltNames.typemismatch_main_person"
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[altnameid mainconid altnameconid],
                target: :constituentid,
                delim: ".",
                delete_sources: true

              if treatment == :variant
                transform Tms::Transforms::NameCompile::DeriveVariantName,
                  mode: :alt
              elsif treatment == :contact_person
                transform Tms::Transforms::NameCompile::DeriveOrgWithContactFromPerson,
                  mode: :alt
              end
            end
          end
        end
      end
    end
  end
end
