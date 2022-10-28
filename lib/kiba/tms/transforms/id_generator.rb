# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      class IdGenerator
        include Tms::Mixins::DateSortable

        def initialize(prefix: '', id_source:, id_target:, sort_on: nil,
                       separator: '.', delete_source: true)
          @prefix = prefix
          @id_source = id_source
          @id_target = id_target
          @sort_on = sort_on
          @separator = separator
          @delete_source = delete_source
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
            .each{ |rows| rows.each{ |row| yield row } }
        end

        private

        attr_reader :prefix, :id_source, :id_target, :sort_on,
          :separator, :delete_source

        def generate_id(row, idx)
          num = idx + 1
          itemid = row[id_source]
          row[id_target] = "#{prefix}#{itemid}#{separator}#{num.to_s.rjust(3, '0')}"
          row.delete(id_source) if delete_source && source_deleteable?
          row
        end

        def generate_ids(rows)
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
