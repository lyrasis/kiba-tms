# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module FromMigrationAdded
          module_function

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_type_cleanup__returned_compile,
                destination: :name_compile__from_migration_added
              },
              transformer: xforms
            )
          end

          # def ntc_needed?
          #   return false unless ntc_done?

          #   ntc_targets.any?(termsource) && treatment == :contact_person
          # end
          # extend Tms::Mixins::NameTypeCleanupable

          def xforms
            Kiba.job_segment do
              prefname = Tms::Constituents.preferred_name_field

              transform FilterRows::FieldEqualTo,
                action: :keep,
                field: :termsource,
                value: "MigrationAdded"
              transform Rename::Field,
                from: :correctname,
                to: prefname
              transform Merge::ConstantValues,
                constantmap: {
                  dropping: "n",
                  relation_type: "_main term"
                }
              transform Delete::FieldsExcept,
                fields: [:constituentid, :contype, prefname, :prefnormorig,
                  :dropping, :termsource, :relation_type]
            end
          end
        end
      end
    end
  end
end
