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
          # @param mergemod [Module] config module for multi table mergeable
          #   table
          # @param targetmod [Module] config module for target table
          def job(source:, dest:, lkup:, mergemod:, targetmod:)
            lookups = get_lookup(lkup)

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: source,
                destination: dest,
                lookup: lookups
              },
              transformer: get_xforms(lookups, mergemod, targetmod)
            )
          end

          def get_lookup(lkup)
            base = []
            base << lkup if Tms.registry.key?(lkup)
            base.select { |job| Kiba::Extend::Job.output?(job) }
          end

          def get_xforms(lookups, mod, targetmod)
            if cleanup_module(mod, targetmod)&.cleanup_done?
              [merge_xforms(lookups, mod), always_xforms]
            else
              [noclean_xforms(mod), always_xforms]
            end
          end

          def cleanup_module(mod, targetmod)
            modname = mod.name.to_s.split("::").last
            targetname = targetmod.name.to_s.split("::").last
            mod = Tms.const_get("#{modname}For#{targetname}TypeCleanup")
          rescue NameError
            nil
          else
            mod
          end

          def merge_xforms(lookups, mod)
            Kiba.job_segment do
              newtypefield = mod.type_field_target
              origtypefield = mod.type_field
              lookup = lookups[0]

              transform Merge::MultiRowLookup,
                lookup: method(lookup).call,
                keycolumn: :lookupkey,
                fieldmap: {
                  newtypefield => :correct_type,
                  :treatment => :treatment,
                  :typenote => :note
                }

              transform FilterRows::FieldEqualTo,
                action: :reject,
                field: :treatment,
                value: "drop"

              transform CombineValues::FromFieldsWithDelimiter,
                sources: [:typenote, mod.note_field],
                target: mod.note_field,
                delim: "; "
              unless origtypefield == newtypefield
                transform do |row|
                  corrtype = row[newtypefield]
                  next row unless corrtype.blank?

                  row[newtypefield] = row[origtypefield]
                  row
                end

                transform Delete::Fields,
                  fields: origtypefield
              end
            end
          end

          def noclean_xforms(mod)
            Kiba.job_segment do
              transform Rename::Field,
                from: mod.type_field_target,
                to: mod.type_field
              transform Append::NilFields,
                fields: %i[treatment]
            end
          end

          def always_xforms
            Kiba.job_segment do
              transform Delete::Fields,
                fields: :lookupkey
            end
          end
        end
      end
    end
  end
end
