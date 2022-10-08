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
                destination: :name_compile__from_con_person_with_inst,
                lookup: lookups
              },
              transformer: xforms,
              helper: config.multi_source_normalizer
            )
          end

          def lookups
            base = []
            if Tms::NameTypeCleanup.done
              ntctargets = Tms::NameTypeCleanup.targets
              if ntctargets.any?('Constituents.person_with_institution')
                base << :name_type_cleanup__for_con_person_with_inst
              end
            end
            base
          end

          def cleanup_ready?
            return false unless Tms::NameTypeCleanup.done

            ntctargets = Tms::NameTypeCleanup.targets
            ntctargets.any?('Constituents.person_with_institution')
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              config = bind.receiver.send(:config)

              job = :name_compile__from_con_person_with_inst
              treatment = config.source_treatment[job]

              transform Tms::Transforms::NameCompile::SelectConPersonWithInst

              transform Append::ToFieldValue,
                field: :constituentid,
                value: '.institution'
              transform Merge::ConstantValue,
                target: :termsource,
                value: 'TMS Constituents.person_with_institution'

              if treatment == :variant
                transform Merge::ConstantValue,
                  target: :relation_type, value: 'variant term'

                transform Rename::Fields, fieldmap: {
                  institution: :variant_term,
                  position: :variant_qualifier
                }
                transform Delete::Fields, fields: Tms::NameCompile.variant_nil
              elsif treatment == :contact_person
                transform Tms::Transforms::NameCompile::DeriveOrgWithContactFromPerson,
                  mode: :main
              end

              if bind.receiver.send(:cleanup_ready?) &&
                  treatment == :contact_person
                transform Tms::Transforms::NameTypeCleanup::OverlayAll,
                  lookup: name_type_cleanup__for_con_person_with_inst,
                  typetarget: {'_main term'=>:contype},
                  nametarget: Tms::Constituents.preferred_name_field
              end
            end
          end
        end
      end
    end
  end
end
