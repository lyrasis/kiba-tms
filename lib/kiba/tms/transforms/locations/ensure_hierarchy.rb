# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Locations
        class EnsureHierarchy
          # @param lookup [Hash]; should be created with csv_to_multi_hash
          # @param inherit [Array<Symbol>] fields that should be populated with the values of the row from which
          #   new hierarchy level is derived
          def initialize(lookup:,
            inherited: %i[storage_location_authority address])
            @lookup = lookup
            @inherited = inherited
            @handled = {}
            @delim = Tms::Locations.hierarchy_delim
          end

          def process(row)
            yield(row)
            parent = row.fetch(:parent_location, "")
            return if parent.blank?
            return if handled.key?(parent)

            handle_parent(row, parent).each { |nr| yield(nr) }
            nil
          end

          private

          attr_reader :lookup, :inherited, :handled, :delim

          def base_row(row, arr)
            {
              location_name: arr.join(delim),
              parent_location: arr[0..-2].join(delim),
              term_source: "Migration.ensureHierarchy"
            }
          end

          def generate_row(row, arr)
            base = base_row(row, arr)
            with_inherited_data = inherit(row, base)
            pad_remaining_fields(row, with_inherited_data)
          end

          # [a b c d] -> [ [a b c d], [a b c], [a b], [a] ]
          def get_levels(arr)
            res = []
            until arr.length == 0
              res << arr.dup
              arr.pop
            end
            res
          end

          def handle_parent(row, parent)
            @handled[parent] = nil
            get_levels(parent.split(delim)).map { |arr|
              handle_parent_level(row, arr)
            }
              .compact
          end

          def handle_parent_level(row, arr)
            arr_s = arr.join(delim)
            return nil if lookup.key?(arr_s)

            @lookup[arr_s] = nil
            @handled[arr_s] = nil

            generate_row(row, arr)
          end

          def inherit(row, hash)
            inherited.each { |field| hash[field] = row.fetch(field, nil) }
            hash
          end

          def pad_remaining_fields(row, hash)
            row.keys.each { |field| hash[field] = nil unless hash.key?(field) }
            hash
          end
        end
      end
    end
  end
end
