# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module MultiTableMergeable
        module TypeOccs
          module_function

          # @param source [Symbol] a reportable for table like
          #   :alt_nums_reportable_for__reference_master
          # @param dest [Symbol] like
          #   :alt_nums_reportable_for__reference_master_type_occs
          # @param mergemod [Module] multi-table mergeable module
          # @param targetmod [Module] target table config module
          def job(source:, dest:, mergemod:, targetmod:)
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: source,
                destination: dest,
                lookup: source
              },
              transformer: xforms(source, mergemod, targetmod)
            )
          end

          def xforms(lookup, mergemod, targetmod)
            Kiba.job_segment do
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: mergemod.type_field
              transform Deduplicate::Table,
                field: :lookupkey
              transform Count::MatchingRowsInLookup,
                lookup: send(lookup),
                keycolumn: :lookupkey,
                targetfield: :occurrences

              if mergemod.respond_to?(:additional_occurrence_ct_fields)
                mergemod.additional_occurrence_ct_fields.each do |field|
                  transform Count::MatchingRowsInLookup,
                    lookup: send(lookup),
                    keycolumn: :lookupkey,
                    targetfield: "occs_with_#{field}".to_sym,
                    conditions: ->(_r, rows) do
                      rows.reject { |row| row[field].blank? }
                    end
                end
              end

              if mergemod.target_ids_mergeable?(targetmod)
                transform Merge::MultiRowLookup,
                  lookup: send(lookup),
                  keycolumn: :lookupkey,
                  fieldmap: {
                    example_rec_ids: :targetrecord,
                    example_values: mergemod.mergeable_value_field
                  },
                  conditions: ->(_r, rows) { rows.first(3) },
                  delim: " ||| "
              end

              transform Delete::Fields,
                fields: [mergemod.mergeable_value_field,
                  mergemod.additional_occurrence_ct_fields,
                  :recordid, :sort, :targetrecord].flatten
            end
          end
        end
      end
    end
  end
end
