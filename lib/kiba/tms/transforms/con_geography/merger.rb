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
            return row if lookup.empty?

            mergerows = lookup[row[id]]
            return row if mergerows.blank?

            handle_bd_place_types(row, mergerows)
            handle_place_notes(row, mergerows)
            return row if auth == :person

            combine_diss_notes(row)
            row
          end

          private

          attr_reader :auth, :fields, :lookup, :id, :notedelim

          def handle_bd_place_types(row, mergerows)
            %w[birth death].each do |type|
              handle_bd_place_type(row, type, mergerows)
            end
          end

          def handle_bd_place_type(row, type, mergerows)
            matches = mergerows.select { |row| row[:type] == type }
            return if matches.empty?

            type = org_type_lookup(type) if auth == :org
            if type == "dissolution"
              set_initial_dissolution_note(row, matches)
            else
              set_bd_place(row, type, matches)
            end
            return if matches.length == 1

            set_bd_place_notes(row, type, matches)
          end

          def set_initial_dissolution_note(row, matches)
            val = matches.first[:mergeable]
            row[:dissnote] = "Dissolution place: #{val}"
          end

          def handle_place_notes(row, mergerows)
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
            target = "geo_#{type}note".to_sym
            prefix = "Additional #{type} place: "
            values = matches[1..-1]
              .map { |row| "#{prefix}#{row[:mergeable]}" }
            row[target] = values.join(notedelim)
            row
          end

          def combine_diss_notes(row)
            val = [row[:dissnote], row[:geo_dissolutionnote]]
              .compact
              .join(notedelim)
            row[:geo_dissolutionnote] = val
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
