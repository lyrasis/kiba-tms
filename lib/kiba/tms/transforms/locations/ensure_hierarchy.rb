# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Locations
        class EnsureHierarchy
          # @param lookup [Hash]; should be created with csv_to_multi_hash
          def initialize(lookup:)
            @lookup = lookup
            @handled = {}
            @delim = Tms.locations.hierarchy_delim
          end

          def process(row)
            yield(row)
            parent = row.fetch(:parent_location, '')
            return if parent.blank?
            return if handled.key?(parent)

            handle_parent(row, parent).each{ |nr| yield(nr) }
            nil
          end

          private

          attr_reader :lookup, :handled, :delim

          def generate_row(row, arr)
            {
              location_name: arr.join(delim),
              parent_location: arr[0..-2].join(delim),
              storage_location_authority: row[:storage_location_authority],
              address: row[:address],
              term_source: 'Migration.ensureHierarchy',
              fulllocid: nil
            }
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
            get_levels(parent.split(delim)).map{ |arr| handle_parent_level(row, arr) }
              .compact
          end

          def handle_parent_level(row, arr)
            arr_s = arr.join(delim)
            return nil if lookup.key?(arr_s)

            @lookup[arr_s] = nil
            @handled[arr_s] = nil
            
            generate_row(row, arr)
          end
          
          
        end
      end
    end
  end
end
