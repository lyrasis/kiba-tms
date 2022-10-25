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
                destination: :name_compile__from_con_org_with_name_parts,
                lookup: lookups
              },
              transformer: xforms,
              helper: Kiba::Tms::NameCompile::multi_source_normalizer
            )
          end

          def ntc_needed?
            return false unless ntc_done?

            ntc_targets.any?('Constituents.orgs_name_detail') &&
              treatment == :contact_person
          end
          extend Tms::Mixins::NameTypeCleanupable

          def lookups
            base = []
            if ntc_needed?
              base << :name_type_cleanup__for_con_org_with_name_parts
            end
            base
          end

          def treatment
            job = :name_compile__from_con_org_with_name_parts
            config.source_treatment[job]
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              treatment = bind.receiver.send(:treatment)

              transform Tms::Transforms::NameCompile::SelectConOrgsWithNameParts

              transform Append::ToFieldValue,
                field: :constituentid,
                value: '.namedetail'
              transform Merge::ConstantValue,
                target: :termsource,
                value: 'TMS Constituents.orgs_name_detail'

              if treatment == :variant
                transform Tms::Transforms::NameCompile::DeriveVariantName,
                  mode: :main,
                  from: :nameparts
              elsif treatment == :contact_person
                transform Tms::Transforms::NameCompile::DeriveAndSetContactFromOrg,
                  mode: :main,
                  person_name_from: :nameparts
              end

              if bind.receiver.send(:ntc_needed?)
                transform Tms::Transforms::NameTypeCleanup::OverlayAll,
                  lookup: name_type_cleanup__for_con_org_with_name_parts,
                  typetarget: {'_main term'=>:contype},
                  nametarget: {
                    '_main term'=>Tms::Constituents.preferred_name_field,
                    'contact_person'=>:related_term
                  }
              end
            end
          end
        end
      end
    end
  end
end
