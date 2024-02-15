# frozen_string_literal: true

module Kiba
  module Tms
    module Jobs
      module ReferenceMaster
        module PlaceAuthorityMerge
          module_function

          def job
            return unless config.used?
            return unless lookups.include?(:places__final_cleaned_lookup)

            Kiba::Extend::Jobs::Job.new(
              files: {
                source: :reference_master__places,
                destination: :reference_master__place_authority_merge,
                lookup: lookups
              },
              transformer: xforms
            )
          end

          def lookups
            base = %i[
              places__final_cleaned_lookup
            ]
            base.select { |job| Kiba::Extend::Job.output?(job) }
          end

          def xforms
            Kiba.job_segment do
              transform Merge::MultiRowLookup,
                lookup: places__final_cleaned_lookup,
                keycolumn: :orig_combined,
                fieldmap: {
                  place: :place,
                  note: :note
                },
                null_placeholder: "%NULLVALUE%"
              transform FilterRows::FieldPopulated,
                action: :keep,
                field: :place
              transform Deduplicate::FieldValues,
                fields: %i[place note],
                sep: "|"
              transform Delete::EmptyFieldValues,
                fields: :note,
                usenull: true
              transform do |row|
                placepub = row[:placepublished]
                places = row[:place].split(Tms.delim)
                next row unless places.include?(placepub)
                next row if places.length == 1

                places.delete(placepub)
                row[:place] = places.join(Tms.delim)
                row
              end
            end
          end
        end
      end
    end
  end
end
