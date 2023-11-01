# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameCompile
        class DeriveAssociationBionote < DeriveAssociations
          def process(row)
            sides = extract_names_by_side(row)
            sides.map { |side, names|
              derive_notes_for_names(names, sides[other(side)])
            }.flatten
              .each { |row| yield row }
            nil
          end

          private

          def derive_notes_for_names(names, notes)
            names.map { |name| derive_notes_for_name(name, notes) }
          end

          def derive_notes_for_name(name, notes)
            notes.map { |note| derive_note_for_name(name, note) }
          end

          def derive_note_for_name(name, note)
            {
              contype: name.type,
              name: name.name,
              relation_type: "bio_note",
              note_text: "#{note.rel}: #{note.name}",
              constituentid: name.id,
              termsource: "Tms Associations"
            }
          end
        end
      end
    end
  end
end
