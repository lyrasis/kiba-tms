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
                destination: jobkey,
                lookup: lookups
              },
              transformer: xforms,
              helper: config.multi_source_normalizer
            )
          end

          def jobkey
            :name_compile__from_con_person_with_inst
          end

          def ntc_needed?
            return false unless ntc_done?

            ntc_targets.any?(termsource) && treatment == :contact_person
          end
          extend Tms::Mixins::NameTypeCleanupable

          def lookups
            base = []
            if ntc_needed?
                base << :name_type_cleanup__for_con_person_with_inst
            end
            base
          end

          def termsource
            "Constituents.person_with_institution"
          end

          def treatment
            config.source_treatment[jobkey]
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              transform Tms::Transforms::NameCompile::SelectConPersonWithInst

              transform Append::ToFieldValue,
                field: :constituentid,
                value: ".institution"
              transform Merge::ConstantValue,
                target: :termsource,
                value: "TMS Constituents.person_with_institution"

              treatment = bind.receiver.send(:treatment)
              if treatment == :variant
                transform Merge::ConstantValue,
                  target: :relation_type, value: "variant term"

                transform Rename::Fields, fieldmap: {
                  institution: :variant_term,
                  position: :variant_qualifier
                }
                transform Delete::Fields, fields: Tms::NameCompile.variant_nil
              elsif treatment == :contact_person
                transform Tms::Transforms::NameCompile::DeriveOrgWithContactFromPerson,
                  mode: :main
              end

              if bind.receiver.send(:ntc_needed?)
                transform Tms::Transforms::NameTypeCleanup::ExplodeMultiNames,
                  lookup: name_type_cleanup__for_con_person_with_inst
                transform Tms::Transforms::NameTypeCleanup::OverlayAll,
                  typetarget: {"_main term"=>:contype},
                  nametarget: Tms::Constituents.preferred_name_field
              end
            end
          end
        end
      end
    end
  end
end
