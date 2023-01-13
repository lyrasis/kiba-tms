# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromCanTypematchAltEstablished
          module_function

          def job
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :con_alt_names__prep_clean,
                destination: :name_compile__from_can_typematch_alt_established
              },
              transformer: xforms,
              helper: Kiba::Tms::NameCompile::multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              job = :name_compile__from_can_typematch_alt_established
              treatment = Tms::NameCompile.source_treatment[job]

              transform Tms::Transforms::NameCompile::SelectCanTypematchEstablished

              transform Merge::ConstantValue, target: :termsource, value: 'TMS ConAltNames.typematch_alt_established'
              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[altnameid mainconid altnameconid],
                target: :constituentid,
                sep: '.',
                delete_sources: true

              if treatment == :variant
                transform Merge::ConstantValue, target: :relation_type, value: 'variant term'
                transform Delete::Fields, fields: :altname
                transform Rename::Fields, fieldmap: {
                  conname: Tms::Constituents.preferred_name_field,
                  altconname: :variant_term,
                  conauthtype: :contype
                }

                rolebuilder = Tms::Services::NameCompile::RoleBuilder.new
                transform do |row, rolebuilder|
                  row[:variant_qualifier] = rolebuilder.call(row)
                  row
                end

                transform Delete::Fields, fields: Tms::NameCompile.variant_nil
              elsif treatment.to_s.end_with?('_note')
                transform Tms::Transforms::NameCompile::AddRelatedAltNameNote, target: treatment
              end
              transform Delete::Fields, fields: Tms::NameCompile.alt_nil
            end
          end
        end
      end
    end
  end
end
