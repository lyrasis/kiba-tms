# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Places
        class CombineExtractedAndProvidedNotes
          EXTRACTED_TO_PROVIDED = {
            proximity: :proximity_note,
            uncertainty: :uncertainty_note,
            misc_note: :place_note
          }
          def initialize(notefield:)
            @notefield = notefield
            @nonoterows = []
            @noterows = {}
            @target = EXTRACTED_TO_PROVIDED[notefield]
          end

          def process(row)
            note = row[notefield]
            note.blank? ? nonoterows << row : populate_noterows(row)
            nil
          end

          def close
            nonoterows.each { |row| yield row }
            noterows.map { |oc, info| handle_rows(info) }
              .flatten
              .each { |row| yield row }
          end

          private

          attr_reader :notefield, :nonoterows, :noterows, :target

          def populate_noterows(row)
            oc = row[:orig_combined]
            note = row[notefield]
            noterows[oc] = {} unless noterows.key?(oc)
            noterows[oc][note] = [] unless noterows[oc].key?(note)
            noterows[oc][note] << row
          end

          def handle_rows(info)
            info.map { |note, rows| handle_note(note, rows) }
              .flatten
          end

          def handle_note(note, rows)
            notehash = eval(note)
            norm = combined_to_hash(rows.first[:norm_combined])
            notehash.each { |field, val|
              handle_note_val(field, val, norm, rows)
            }
            rows
          end

          # @param [String] :norm_combined or :orig_combined value
          # @return [Hash]
          def combined_to_hash(combined)
            combined.split("|||")
              .map { |lvl| lvl.split(": ") }
              .to_h
              .transform_keys { |key| key.to_sym }
          end

          def handle_note_val(field, vals, norm, rows)
            place = norm[field]
            if rows.length == 1
              add_note_vals_to_row(place, field, vals, rows[0])
            else
              rows = select_rows(place, field, vals, norm, rows)
              rows&.each { |row| add_note_vals_to_row(place, field, vals, row) }
            end
          end

          def add_note_vals_to_row(place, field, vals, row)
            vals.each { |val| add_note_val_to_row(place, field, val, row) }
          end

          def add_note_val_to_row(place, field, val, row)
            add_note(format_note(val, place, field), row)
          end

          def select_rows(place, field, vals, norm, rows)
            literal_matches = literal_matcher(place, rows)
            return literal_matches[:match] if literal_matches

            select_rows_by_type(field, rows)
          end

          def select_rows_by_type(field, rows)
            if Tms::Places.hierarchy_fields.include?(field)
              rows.select { |row| row[:termtype] == "hier" }
            else
              nonhier = rows.select { |row| row[:termtype] == "nonhier" }
              return [] if nonhier.empty?

              [nonhier[0]]
            end
          end

          def format_note(val, place, field)
            case notefield
            when :proximity
              "#{val} #{place}"
            when :uncertainty
              "#{place} (#{field}) #{val}"
            when :misc_note
              cleaned_val = val.sub(/([[:blank:]]|[[:punct:]])+/, "")
                .sub(/([[:blank:]]|[[:punct:]])+$/, "")
              "#{place} (#{cleaned_val})"
            end
          end

          def add_note(note, row)
            if row[target].blank?
              row[target] = note
            else
              row[target] << "; #{note}"
            end
          end

          def literal_matcher(place, rows)
            return if place.nil?
            matches = rows.group_by do |row|
              row[:place].downcase.include?(place.downcase)
            end
            return nil unless matches.key?(true)

            matches.transform_keys { |key| (key == true) ? :match : :nomatch }
          end
        end
      end
    end
  end
end
