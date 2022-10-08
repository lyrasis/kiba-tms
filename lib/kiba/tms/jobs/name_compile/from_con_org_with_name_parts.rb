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

          def lookups
            base = []
            if cleanup_ready?
              base << :name_type_cleanup__for_con_org_with_name_parts
            end
            base
          end

          def cleanup_ready?
            return false unless Tms::NameTypeCleanup.done

            ntctargets = Tms::NameTypeCleanup.targets
            ntctargets.any?('Constituents.orgs_name_detail')
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)
              job = :name_compile__from_con_org_with_name_parts
              treatment = config.source_treatment[job]

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

              if bind.receiver.send(:cleanup_ready?)
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
