# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameCompile
        class DisambiguateConstituentDuplicates
          def initialize
            @namefield = Tms::Constituents.preferred_name_field
            @normfield = :norm
            @counter = {}
            @suffix = Tms::Constituents.duplicate_disambiguation_string
            @normer = Kiba::Extend::Utils::StringNormalizer.new(
              mode: :cspaceid
            )
          end

          def process(row)
            key = "#{row[:contype]} #{row[:norm]}"
            populate_counter(key, row)

            nil
          end

          def close
            singles = counter.group_by { |key, arr| arr.length == 1 }
              .transform_values { |arr| arr.to_h }
            singles[true].values.flatten.each { |row| yield row }
            singles[false].values.flatten
              .map { |row| disambiguate(row) }
              .each { |row| yield row }
          end

          private

          attr_reader :namefield, :normfield, :counter, :suffix, :normer

          def populate_counter(key, row)
            if counter.key?(key)
              counter[key] << row
            else
              counter[key] = [row]
            end
          end

          def disambiguate(row)
            return row if dropped?(row)
            int = row[:constituentid].sub(/_exploded\d+$/, "")
            toadd = suffix.dup.sub("%int%", int)
            newname = "#{row[namefield]}#{toadd}"
            row[namefield] = newname
            row[normfield] = normer.call(newname)
            row
          end

          def dropped?(row)
            true if row[namefield] == Tms::Names.dropped_name_indicator
          end
        end
      end
    end
  end
end
