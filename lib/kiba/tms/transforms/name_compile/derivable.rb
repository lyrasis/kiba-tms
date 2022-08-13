# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameCompile
        # Mix-in module to derive name compilation rows
        module Derivable
          def derive_main_org(row, orgnamefield, mode = :main)
            row[:contype] = 'Organization'
            row[Tms::Constituents.preferred_name_field] = row[orgnamefield]
            row[:relation_type] = 'main term'
            del = [Tms::NameCompile.org_nil, Tms::NameCompile.derived_nil]
            del << Tms::NameCompile.alt_nil if mode == :alt
            del.flatten.each{ |field| row.delete(field) }
            row
          end

          def derive_main_person(row, personnamefield, mode = :main)
            row[:contype] = 'Person'
            row[Tms::Constituents.preferred_name_field] = row[personnamefield]
            row[:relation_type] = 'main term'
            del = [Tms::NameCompile.person_nil, Tms::NameCompile.derived_nil]
            del << Tms::NameCompile.alt_nil if mode == :alt
            del.flatten.each{ |field| row.delete(field) }
            row
          end

          # @param row [Hash] from which note row will be derived. id, name, source, will be copied from
          #   this row
          # @param notefield [Symbol] target field name for note
          # @param text [String] content of note field
          def derive_note(row, notefield, text)
            newrow = row.dup
            newrow[:relation_type] = notefield
            newrow[:note_text] = text
            newrow
          end
        end
      end
    end
  end
end
