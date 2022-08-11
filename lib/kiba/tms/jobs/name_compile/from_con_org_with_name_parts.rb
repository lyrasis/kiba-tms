# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromConOrgWithNameParts
          module_function

          def job
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :constituents__for_compile,
                destination: :name_compile__from_con_org_with_name_parts
              },
              transformer: xforms,
              helper: Kiba::Tms::NameCompile::multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              job = :name_compile__from_con_org_with_name_parts
              treatment = Tms::NameCompile.source_treatment[job]
              
              transform Tms::Transforms::NameCompile::SelectConOrgsWithNameParts
              transform Tms::Transforms::Constituents::ExtractPersonFromNameParts, target: :personname
              
              transform Append::ToFieldValue, field: :constituentid, value: '.namedetail'
              transform Merge::ConstantValue, target: :termsource, value: 'TMS Constituents.orgs_name_detail'

              if treatment == :variant
                transform Merge::ConstantValue, target: :relation_type, value: 'variant term'
                
                transform Rename::Fields, fieldmap: {
                  personname: :variant_term,
                  position: :variant_qualifier
                }
                transform Delete::Fields, fields: Tms::NameCompile.variant_nil
              elsif treatment.to_s.start_with?('related_')
                targetfield = treatment.to_s.delete_prefix('related_').to_sym

                transform Tms::Transforms::NameCompile::RelatedPersonForOrg, target: targetfield
              end
            end
          end
        end
      end
    end
  end
end
