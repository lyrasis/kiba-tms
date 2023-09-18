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
          #   :alt_nums_reportable_for__reference_master_cleanup_merge
          # @param lkup [Symbol] like
          #   :alt_nums_for_reference_master_type_cleanup__final
          def job(source:, dest:, lkup:, mod:)
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: source,
                destination: dest,
                lookup: lkup
              },
              transformer: xforms(lkup, mod)
            )
          end

          def xforms(lkup, mod)
            Kiba.job_segment do
              typefield = mod.type_field_target

              transform Merge::MultiRowLookup,
                lookup: method(lkup).call,
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
        end
      end
    end
  end
end
