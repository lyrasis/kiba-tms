# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromConOrgWithSingleNamePartNoPosition
          module_function

          def job
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :constituents__for_compile,
                destination: :name_compile__from_con_org_with_single_name_part_no_position
              },
              transformer: xforms,
              helper: Kiba::Tms::NameCompile::multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              job = :name_compile__from_con_org_with_single_name_part_no_position
              treatment = Tms::NameCompile.source_treatment[job]

              transform Tms::Transforms::NameCompile::SelectConOrgsWithSingleNamePartNoPosition

              if treatment == :variant
                transform Append::ToFieldValue, field: :constituentid, value: '.singlenamedetail'
                transform Merge::ConstantValue, target: :termsource, value: 'TMS Constituents.orgs_single_name_detail'

                transform Merge::ConstantValue, target: :relation_type, value: 'variant term'
                
                transform Rename::Field, from: :lastname, to: :variant_term
                transform Delete::Fields, fields: Tms::NameCompile.variant_nil
              end
            end
          end
        end
      end
    end
  end
end
