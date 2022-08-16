# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module NameCompile
        module DuplicatesFlagged
          module_function

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
                      name_compile__constituent_duplicates
                      name_compile__main_duplicates
                     ]
            base << :name_compile__variant_duplicates if Tms::NameCompile.deduplicate_categories.any?(:variant)
            base << :name_compile__related_duplicates if Tms::NameCompile.deduplicate_categories.any?(:related)
            base << :name_compile__note_duplicates if Tms::NameCompile.deduplicate_categories.any?(:note)
            base
          end
          
          def xforms
            Kiba.job_segment do
              transform Merge::MultiRowLookup,
                lookup: name_compile__constituent_duplicates,
                keycolumn: :fingerprint,
                fieldmap: {constituent_duplicate: :duplicate}

              transform Merge::MultiRowLookup,
                lookup: name_compile__main_duplicates,
                keycolumn: :fingerprint,
                fieldmap: {name_duplicate: :duplicate}

              if Tms::NameCompile.deduplicate_categories.any?(:variant)
                transform Merge::MultiRowLookup,
                  lookup: name_compile__variant_duplicates,
                  keycolumn: :fingerprint,
                  fieldmap: {variant_duplicate: :duplicate}
              end

              if Tms::NameCompile.deduplicate_categories.any?(:related)
                transform Merge::MultiRowLookup,
                  lookup: name_compile__related_duplicates,
                  keycolumn: :fingerprint,
                  fieldmap: {related_duplicate: :duplicate}
              end

              if Tms::NameCompile.deduplicate_categories.any?(:note)
                transform Merge::MultiRowLookup,
                  lookup: name_compile__note_duplicates,
                  keycolumn: :fingerprint,
                  fieldmap: {note_duplicate: :duplicate}
              end

              transform Delete::Fields, fields: :fingerprint
            end
          end
        end
      end
    end
  end
end
