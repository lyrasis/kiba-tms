# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConGeography
        class PersonMerger
          def initialize
            @lookup = Tms.get_lookup(
              jobkey: :prep__con_geography,
              column: :constituentid
            )
            @id = :constituentid
            @notedelim = '%CR%'
          end

          def process(row)
            %i[birthplace geo_birthnote deathplace geo_deathnote
               geo_note].each do |field|
              row[field] = nil
            end
            return row if lookup.empty?

            mergerows = lookup[row[id]]
            return row if mergerows.blank?

            handle_bd_place_types(row, mergerows)
            handle_place_notes(row, mergerows)
            row
          end

          private

          attr_reader :lookup, :id, :notedelim

          def handle_bd_place_type(row, type, mergerows)
            matches = mergerows.select{ |row| row[:type] == type }
            return if matches.empty?

            set_bd_place(row, type, matches)
            return if matches.length == 1

            set_bd_place_notes(row, type, matches)
          end

          def handle_bd_place_types(row, mergerows)
            %w[birth death].each do |type|
              handle_bd_place_type(row, type, mergerows)
            end
          end

          def handle_place_notes(row, mergerows)
            matches = mergerows.select{ |row| row[:type].blank? }
            return if matches.empty?

            row[:geo_note] = matches.map{ |row| row[:mergeable] }
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
              .map{ |row| "#{prefix}#{row[:mergeable]}" }
            row[target] = values.join(notedelim)
            row
          end
        end
      end
    end
  end
end
