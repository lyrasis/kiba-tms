# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module DuplicatesFlagged
          module_function

          def desc
            <<~DESC
              Intermediate file for review and generating reports

              - Initial compiled terms with duplicate terms flagged according to
                :deduplicate_categories config
              - :sort field added (contype + norm + relation type
            DESC
          end

          def job
            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :name_compile__raw,
                destination: :name_compile__duplicates_flagged,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = %i[
              name_compile__main_duplicates
            ]
            if lookup_eligible?(:variant)
              base << :name_compile__variant_duplicates
            end
            if lookup_eligible?(:related)
              base << :name_compile__related_duplicates
            end
            if lookup_eligible?(:note)
              base << :name_compile__note_duplicates
            end
            base.select{ |job| Tms.job_output?(job) }
          end

          def lookup_eligible?(type)
            config.deduplicate_categories.any?(type) &&
              Tms.job_output?("name_compile__#{type}_duplicates".to_sym)
          end

          def xforms
            bind = binding

            Kiba.job_segment do
              if bind.receiver.send(:lookups).any?(
                :name_compile__main_duplicates
              )
              transform Merge::MultiRowLookup,
                lookup: name_compile__main_duplicates,
                keycolumn: :fingerprint,
                fieldmap: {
                  name_duplicate_all: :duplicate_all,
                  name_duplicate: :duplicate
                }
              end

              if bind.receiver.send(:lookup_eligible?, :variant)
                transform Merge::MultiRowLookup,
                  lookup: name_compile__variant_duplicates,
                  keycolumn: :fingerprint,
                  fieldmap: {
                    variant_duplicate_all: :duplicate_all,
                    variant_duplicate: :duplicate
                  }
              end

              if bind.receiver.send(:lookup_eligible?, :related)
                transform Merge::MultiRowLookup,
                  lookup: name_compile__related_duplicates,
                  keycolumn: :fingerprint,
                  fieldmap: {
                    related_duplicate_all: :duplicate_all,
                    related_duplicate: :duplicate
                  }
              end

              if bind.receiver.send(:lookup_eligible?, :note)
                transform Merge::MultiRowLookup,
                  lookup: name_compile__note_duplicates,
                  keycolumn: :fingerprint,
                  fieldmap: {
                    note_duplicate_all: :duplicate_all,
                    note_duplicate: :duplicate
                  }
              end

              transform Cspace::NormalizeForID, source: :name, target: :norm
              transform Tms::Transforms::Names::NormalizeContype

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[contype_norm norm relation_type],
                target: :sort,
                delim: " ",
                delete_sources: false
              transform Delete::Fields,
                fields: %i[fingerprint contype_norm norm]
            end
          end
        end
      end
    end
  end
end
