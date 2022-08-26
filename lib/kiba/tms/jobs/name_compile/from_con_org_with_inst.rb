# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromConOrgWithInst
          module_function

          def job
            Kiba::Extend::Jobs::MultiSourcePrepJob.new(
              files: {
                source: :constituents__for_compile,
                destination: :name_compile__from_con_org_with_inst
              },
              transformer: xforms,
              helper: Kiba::Tms::NameCompile::multi_source_normalizer
            )
          end

          def xforms
            Kiba.job_segment do
              treatment = Tms::NameCompile.source_treatment[:name_compile__from_con_org_with_inst]
              transform FilterRows::WithLambda,
                action: :keep,
                lambda: ->(row) do
                  type = row[:contype]
                  type && type.start_with?('Organization')
                end
              transform FilterRows::FieldPopulated, action: :keep, field: :institution
              transform Append::ToFieldValue, field: :constituentid, value: '.institution'
              transform Merge::ConstantValue, target: :termsource, value: 'TMS Constituents.orgs_institution'

              if treatment == :variant
                transform Merge::ConstantValue, target: :relation_type, value: 'variant term'
                
                transform Rename::Field, from: :institution, to: :variant_term
              end
              
              transform Delete::Fields, fields: Tms::NameCompile.org_nil
            end
          end
        end
      end
    end
  end
end
