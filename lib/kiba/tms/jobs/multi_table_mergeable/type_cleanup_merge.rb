# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MultiTableMergeable
        module TypeCleanupMerge
          module_function

          # @param source [Symbol] a reportable for table like
          #   :alt_nums_reportable_for__reference_master
          # @param dest [Symbol] like
          #   :alt_nums_reportable_for__reference_master_type_cleanup_merge
          # @param lkup [Symbol] like
          #   :alt_nums_for_reference_master_type_cleanup__final
          # @param mod [Module]
          def job(source:, dest:, lkup:, mod:)
            lookups = get_lookup(lkup)

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: source,
                destination: dest,
                lookup: lookups
              },
              transformer: get_xforms(lookups, mod)
            )
          end

          def get_lookup(lkup)
            base = []
            base << lkup if Tms.registry.key?(lkup)
            base.select { |job| Kiba::Extend::Job.output?(job) }
          end

          def get_xforms(lookups, mod)
            return passthrough_xforms if lookups.empty?

            xforms(lookups, mod)
          end

          def xforms(lookups, mod)
            Kiba.job_segment do
              typefield = mod.type_field_target
              lookup = lookups[0]

              transform Merge::MultiRowLookup,
                lookup: method(lookup).call,
                keycolumn: :lookupkey,
                fieldmap: {
                  typefield => :correct_type,
                  :treatment => :treatment,
                  :typenote => :note
                }
              transform FilterRows::FieldEqualTo,
                action: :reject,
                field: :treatment,
                value: "drop"

              transform Delete::Fields,
                fields: [mod.type_field, :lookupkey]
              transform CombineValues::FromFieldsWithDelimiter,
                sources: [:typenote, mod.note_field],
                target: mod.note_field,
                delim: "; "
            end
          end

          def passthrough_xforms
            Kiba.job_segment do
              # passthrough
            end
          end
        end
      end
    end
  end
end
