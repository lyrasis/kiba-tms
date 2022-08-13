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
              
              transform Append::ToFieldValue, field: :constituentid, value: '.namedetail'
              transform Merge::ConstantValue, target: :termsource, value: 'TMS Constituents.orgs_name_detail'

              if treatment == :variant
                transform Tms::Transforms::NameCompile::DeriveVariantName, mode: :main, from: :nameparts
              elsif treatment == :contact_person
                transform Tms::Transforms::NameCompile::DeriveAndSetContactFromOrg,
                  mode: :main,
                  person_name_from: :nameparts
              end
            end
          end
        end
      end
    end
  end
end
