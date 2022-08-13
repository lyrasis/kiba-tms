# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromConPersonWithInst
          module_function

          def job
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :constituents__for_compile,
                destination: :name_compile__from_con_person_with_inst
              },
              transformer: xforms,
              helper: Kiba::Tms::NameCompile::multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              job = :name_compile__from_con_person_with_inst
              treatment = Tms::NameCompile.source_treatment[job]
              
              transform Tms::Transforms::NameCompile::SelectConPersonWithInst
              
              transform Append::ToFieldValue, field: :constituentid, value: '.institution'
              transform Merge::ConstantValue, target: :termsource, value: 'TMS Constituents.person_with_institution'

              if treatment == :variant
                transform Merge::ConstantValue, target: :relation_type, value: 'variant term'
                
                transform Rename::Fields, fieldmap: {
                  institution: :variant_term,
                  position: :variant_qualifier
                }
                transform Delete::Fields, fields: Tms::NameCompile.variant_nil
              elsif treatment == :contact_person
                transform Tms::Transforms::NameCompile::DeriveOrgWithContactFromPerson, mode: :main
              end
            end
          end
        end
      end
    end
  end
end
