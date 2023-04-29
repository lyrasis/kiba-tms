# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameCompile
        class AddRelatedAltNameNote
          def initialize(target:)
            @target = target
            @namefield = Tms::Constituents.preferred_name_field
            @relbuilder = Tms::Services::NameCompile::RoleBuilder.new
            @mainnote = Tms::Services::NameCompile::RelatedNameNoteText.new(mode: :main)
            @altnote = Tms::Services::NameCompile::RelatedNameNoteText.new(mode: :alt)
          end

          # @private
          def process(row)
            @maintype = row[:conauthtype]
            @alttype = row[:altauthtype]
            @auth_alt = row[:altconname]
            @mainname = row[:conname]
            @altname = auth_alt.blank? ? row[:altname] : auth_alt
            @relator = relbuilder.call(row)

            build_rows(row).each { |row| yield row }
            nil
          end

          private

          attr_reader :target, :namefield, :relbuilder,
            :maintype, :alttype, :auth_alt, :mainname, :altname, :relator,
            :mainnote, :altnote

          def add_shared_fields(row, fields)
            (fields - row.keys).each { |field| row[field] = nil }
            row
          end

          def alt_name_row(row)
            row[:contype] = alttype
            row[namefield] = altname
            row[:relation_type] = target
            row[:note_text] = derive_name_note_for_alt
            [Tms::NameCompile.variant_nil,
              Tms::NameCompile.alt_nil].flatten.each { |field|
              row.delete(field)
            }
            row
          end

          def build_rows(row)
            initial = [main_name_row(row.dup)]
            initial << alt_name_row(row.dup) unless auth_alt.blank?
            fields = initial.map { |irow| irow.keys }.flatten.uniq
            initial.map { |irow| add_shared_fields(irow, fields) }
          end

          def derive_name_note_for_alt
            altnote.call(authtype: maintype, name: mainname, relator: relator)
          end

          def derive_name_note_for_main
            mainnote.call(authtype: alttype, name: altname, relator: relator)
          end

          def main_name_row(row)
            row[:contype] = maintype
            row[namefield] = row[:conname]
            row[:relation_type] = target
            row[:note_text] = derive_name_note_for_main
            [Tms::NameCompile.variant_nil,
              Tms::NameCompile.alt_nil].flatten.each { |field|
              row.delete(field)
            }
            row
          end
        end
      end
    end
  end
end
