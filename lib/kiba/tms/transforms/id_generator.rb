# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      class IdGenerator
        include Tms::Mixins::DateSortable
        # @param omit_suffix_if_single [Boolean] if true and there is only one
        #   row with a given id source value, no suffix is added to id_target
        #   value
        def initialize(prefix: '', id_source:, id_target:, sort_on: nil,
                       separator: '.', delete_source: true,
                       omit_suffix_if_single: true)
          @prefix = prefix
          @id_source = id_source
          @id_target = id_target
          @sort_on = sort_on
          @separator = separator
          @delete_source = delete_source
          @omit_suffix_if_single = omit_suffix_if_single
          @data = {}
        end

        # @private
        def process(row)
          id = row[id_source]
          @data.key?(id) ? @data[id] << row : @data[id] = [row]
          nil
        end

        # @private
        def close
          @data.values
            .map{ |rows| generate_ids(rows) }
            .map{ |rows| delete_sources(rows) }
            .each{ |rows| rows.each{ |row| yield row } }
        end

        private

        attr_reader :prefix, :id_source, :id_target, :sort_on,
          :separator, :delete_source, :omit_suffix_if_single

        def delete_sources(rows)
          return rows unless delete_source
          return rows unless source_deleteable?

          rows.map{ |row| row.delete(id_source); row }
        end

        def generate_id(row, idx)
          num = idx + 1
          itemid = row[id_source]
          id = "#{prefix}#{itemid}#{separator}#{num.to_s.rjust(3, '0')}"
          row[id_target] = id
          row
        end

        def generate_ids(rows)
          if rows.length == 1 && omit_suffix_if_single
            rows.map{ |row| row[id_target] = row[id_source]; row }
          else
            generate_multirow_ids(rows)
          end
        end

        def generate_multirow_ids(rows)
          if sort_on
            rows.sort_by{ |row| sortable_date_from_row(row, sort_on) }
              .map.with_index{ |row, idx| generate_id(row, idx) }
          else
            rows.map.with_index{ |row, idx| generate_id(row, idx) }
          end
        end

        def source_deleteable?
          true unless id_source == id_target
        end
      end
    end
  end
end
