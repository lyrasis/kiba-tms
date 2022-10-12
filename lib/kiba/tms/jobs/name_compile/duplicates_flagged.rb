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
            if Tms::NameCompile.deduplicate_categories.any?(:variant)
              base << :name_compile__variant_duplicates
            end
            if Tms::NameCompile.deduplicate_categories.any?(:related)
              base << :name_compile__related_duplicates
            end
            if Tms::NameCompile.deduplicate_categories.any?(:note)
              base << :name_compile__note_duplicates
            end
            base
          end

          def xforms
            Kiba.job_segment do
              transform Merge::MultiRowLookup,
                lookup: name_compile__main_duplicates,
                keycolumn: :fingerprint,
                fieldmap: {
                  name_duplicate_all: :duplicate_all,
                  name_duplicate: :duplicate
                }

              if Tms::NameCompile.deduplicate_categories.any?(:variant)
                transform Merge::MultiRowLookup,
                  lookup: name_compile__variant_duplicates,
                  keycolumn: :fingerprint,
                  fieldmap: {
                    variant_duplicate_all: :duplicate_all,
                    variant_duplicate: :duplicate
                  }
              end

              if Tms::NameCompile.deduplicate_categories.any?(:related)
                transform Merge::MultiRowLookup,
                  lookup: name_compile__related_duplicates,
                  keycolumn: :fingerprint,
                  fieldmap: {
                    related_duplicate_all: :duplicate_all,
                    related_duplicate: :duplicate
                  }
              end

              if Tms::NameCompile.deduplicate_categories.any?(:note)
                transform Merge::MultiRowLookup,
                  lookup: name_compile__note_duplicates,
                  keycolumn: :fingerprint,
                  fieldmap: {
                    note_duplicate_all: :duplicate_all,
                    note_duplicate: :duplicate
                  }
              end

              transform Cspace::NormalizeForID, source: :name, target: :norm
              transform Tms::Transforms::Constituents::NormalizeContype

              transform CombineValues::FromFieldsWithDelimiter,
                sources: %i[contype_norm norm relation_type],
                target: :sort,
                sep: ' ',
                delete_sources: false
              transform Delete::Fields, fields: %i[fingerprint contype_norm norm]
            end
          end
        end
      end
    end
  end
end
