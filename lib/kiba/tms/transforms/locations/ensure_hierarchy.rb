# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Locations
        class EnsureHierarchy
          # @param lookup [Hash]; should be created with csv_to_multi_hash
          # @param inherit [Array<Symbol>] fields that should be populated with
          #   the values of the row from which new hierarchy level is derived
          def initialize(lookup:,
            inherited: %i[storage_location_authority address])
            @lookup = lookup
            @inherited = inherited
            @abbrev = Tms::Locations.terms_abbreviated
            @inherited << :tmslocationstring if @abbrev
            @direction = Tms::Locations.term_hierarchy_direction
            @handled = {}
            @delim = Tms::Locations.hierarchy_delim
          end

          def process(row)
            handled[row[:location_name]] = nil
            yield(row)

            parent = row[:parent_location]
            return if parent.blank?
            return if handled.key?(parent)

            handle_parent(row, parent).each { |newrow| yield(newrow) }
            nil
          end

          private

          attr_reader :lookup, :inherited, :abbrev, :direction, :handled, :delim

          def handle_parent(row, parent)
            handled[parent] = nil
            get_levels(row, parent.split(delim)).map { |arr|
              handle_parent_level(row, arr)
            }
              .compact
          end

          # [a b c d] -> [ [a b c d], [a b c], [a b], [a] ]
          def get_levels(row, arr)
            res = []
            until arr.length == 0
              res << arr.dup
              case direction
              when :narrow_to_broad
                arr.shift
              when :broad_to_narrow
                arr.pop
              end
            end
            res
          end

          def handle_parent_level(row, arr)
            arr_s = arr.join(delim)
            return nil if lookup.key?(arr_s)

            @lookup[arr_s] = nil
            handled[arr_s] = nil

            generate_row(row, arr)
          end

          def generate_row(row, arr)
            base = base_row(row, arr)
            with_inherited_data = inherit(row, base)
            fix_string(with_inherited_data)
            pad_remaining_fields(row, with_inherited_data)
          end

          def base_row(row, arr)
            parent = case direction
            when :narrow_to_broad
              arr.shift
              arr.join(delim)
            when :broad_to_narrow
              arr[0..-2].join(delim)
            end
            {
              location_name: arr.join(delim),
              parent_location: parent,
              term_source: "Migration.ensureHierarchy"
            }
          end

          def inherit(row, hash)
            inherited.each { |field| hash[field] = row.fetch(field, nil) }
            hash
          end

          def fix_string(row)
            return row unless abbrev

            orig = row[:tmslocationstring]
            return row if orig.blank?

            len = row[:location_name].split(delim).length
            row[:tmslocationstring] = orig.split(", ").first(len).join(", ")
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
