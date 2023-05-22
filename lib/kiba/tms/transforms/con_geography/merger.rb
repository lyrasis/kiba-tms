# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConGeography
        class Merger
          # @param auth [:person, :org]
          # @param lookup [Hash]
          def initialize(auth:, lookup:)
            @auth = auth
            @lookup = lookup
            @id = :constituentid
            @notedelim = "%CR%"
            case auth
            when :person
              @fields = %i[birthplace geo_birthnote deathplace geo_deathnote
                geo_note]
            when :org
              @fields = %i[foundingplace geo_foundingnote
                geo_dissolutionnote
                geo_note]
            end
          end

          def process(row)
            fields.each do |field|
              row[field] = nil
            end

            mergerows = lookup.empty? ? [] : lookup[row[id]]

            handle_bd_place_types(row, mergerows)
            handle_place_notes(row, mergerows)
            return row if auth == :person

            combine_diss_notes(row)
            row
          end

          private

          attr_reader :auth, :fields, :lookup, :id, :notedelim

          def handle_bd_place_types(row, mergerows)
            return if mergerows.blank? && auth == :person

            %w[birth death].each do |type|
              handle_bd_place_type(row, type, mergerows)
            end
          end

          def handle_bd_place_type(row, type, mergerows)
            matches = if mergerows.blank?
              []
            else
              mergerows.select { |row| row[:type] == type }
            end
            type = org_type_lookup(type) if auth == :org
            return if matches.empty? unless type == "founding"

            if type == "founding"
              handle_founding_and_nationality(row, matches)
              return
            elsif type == "dissolution"
              set_initial_dissolution_note(row, matches)
            else
              set_bd_place(row, type, matches)
            end
            return if matches.length == 1

            set_bd_place_notes(row, type, matches)
          end

          def handle_founding_and_nationality(row, matches)
            nationality = row[:nationality]
            row.delete(:nationality)
            case Tms::Orgs.foundingplace_handling
            when :congeo_nationality
              founding_congeo_nationality(row, matches, nationality)
            when :congeo_only
              founding_congeo_only(row, matches, nationality)
            when :nationality_only
              founding_nationality_only(row, matches, nationality)
            end
          end

          def founding_congeo_nationality(row, matches, nationality)
            if matches.empty?
              row[:foundingplace] = nationality unless nationality.blank?
            else
              set_bd_place(row, "founding", matches)
              set_bd_place_notes(row, "founding", matches) if matches.length > 1
              add_nationality_note(row, nationality)
            end
            row
          end

          def founding_congeo_only(row, matches, nationality)
            unless matches.empty?
              set_bd_place(row, "founding", matches)
              set_bd_place_notes(row, "founding", matches) if matches.length > 1
            end
            add_nationality_note(row, nationality)
            row
          end

          def founding_nationality_only(row, matches, nationality)
            row[:foundingplace] = nationality unless nationality.blank?
            unless matches.empty?
              matches.unshift(nil)
              set_bd_place_notes(row, "founding", matches)
              fix_founding_note(row)
            end
            row
          end

          def fix_founding_note(row)
            note = row[:geo_foundingnote]
            fixed = note.sub(/^Additional f/, "F")
            row[:geo_foundingnote] = fixed
          end

          def add_nationality_note(row, nationality)
            return row if nationality.blank?

            existing = row[:geo_foundingnote]
            natnote = "Nationality: #{nationality}"
            if existing.nil?
              row[:geo_foundingnote] = natnote
            else
              row[:geo_foundingnote] << "%CR%#{natnote}"
            end
            row
          end

          def set_initial_dissolution_note(row, matches)
            val = matches.first[:mergeable]
            row[:dissnote] = "Dissolution place: #{val}"
          end

          def handle_place_notes(row, mergerows)
            return if mergerows.blank?

            matches = mergerows.select { |row| row[:type].blank? }
            return if matches.empty?

            row[:geo_note] = matches.map { |row| row[:mergeable] }
              .join(notedelim)
            row
          end

          def set_bd_place(row, type, matches)
            target = "#{type}place".to_sym
            row[target] = matches.first[:mergeable]
            row
          end

          def set_bd_place_notes(row, type, matches)
            return if matches.empty?

            target = "geo_#{type}note".to_sym
            prefix = "Additional #{type} place: "
            values = matches[1..-1]
              .map { |row| "#{prefix}#{row[:mergeable]}" }
            row[target] = values.join(notedelim)
            row
          end

          def combine_diss_notes(row)
            val = [row[:dissnote], row[:geo_dissolutionnote]]
              .reject { |element| element.blank? }
              .join(notedelim)
            row[:geo_dissolutionnote] = val.empty? ? nil : val
            row.delete(:dissnote)
          end

          def org_type_lookup(type)
            lkp = {
              "birth" => "founding",
              "death" => "dissolution"
            }
            lkp[type]
          end
        end
      end
    end
  end
end
