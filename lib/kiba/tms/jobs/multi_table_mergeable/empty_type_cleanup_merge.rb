# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MultiTableMergeable
        module EmptyTypeCleanupMerge
          module_function

          # @param source [Symbol] a reportable for table like
          #   :alt_nums_reportable_for__objects
          # @param dest [Symbol] like
          #   :alt_nums_reportable_for__objects_empty_type_cleanup_merge
          # @param lkup [Symbol] like
          #   :alt_nums_for_objects_empty_type_cleanup__final
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
              origtypefield = mod.type_field
              lookup = lookups[0]

              transform Merge::MultiRowLookup,
                lookup: method(lookup).call,
                keycolumn: :sort,
                fieldmap: {
                  typefield => typefield,
                  :numbernote => :note
                }
              transform FilterRows::FieldEqualTo,
                action: :reject,
                field: typefield,
                value: "DROP"

              transform do |row|
                origtype = row[origtypefield]
                next row unless origtype.blank?

                corrected_type = row[typefield]
                row[origtypefield] = corrected_type
                lkupbase = row[:lookupkey].strip
                row[:lookupkey] = [lkupbase, corrected_type].join(" ").strip
                row
              end

              transform Delete::Fields,
                fields: typefield

              transform CombineValues::FromFieldsWithDelimiter,
                sources: [mod.note_field, :numbernote],
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
