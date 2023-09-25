# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      class IdGenerator
        include Tms::Mixins::DateSortable
        # @param omit_suffix_if_single [Boolean] if true and there is only one
        #   row with a given id source value, no suffix is added to id_target
        #   value
        def initialize(id_source:, id_target:, prefix: "", sort_on: nil,
          sort_type: :date, separator: ".", delete_source: true,
          omit_suffix_if_single: true, padding: 3)
          @prefix = prefix
          @id_source = id_source
          @id_target = id_target
          @sort_on = sort_on
          @sort_type = sort_type
          @separator = separator
          @delete_source = delete_source
          @omit_suffix_if_single = omit_suffix_if_single
          @padding = padding
          @data = {}
        end

        # @private
        def process(row)
          id = row[id_source].to_s
          @data.key?(id) ? @data[id] << row : @data[id] = [row]
          nil
        end

        # @private
        def close
          @data.values
            .map { |rows| generate_ids(rows) }
            .map { |rows| delete_sources(rows) }
            .each { |rows| rows.each { |row| yield row } }
        end

        private

        attr_reader :prefix, :id_source, :id_target, :sort_on, :sort_type,
          :separator, :delete_source, :omit_suffix_if_single, :padding

        def delete_sources(rows)
          return rows unless delete_source
          return rows unless source_deleteable?

          rows.map { |row|
            row.delete(id_source)
            row
          }
        end

        def generate_id(row, idx)
          num = idx + 1
          itemid = row[id_source]
          id = "#{prefix}#{itemid}#{separator}#{num.to_s.rjust(padding, "0")}"
          row[id_target] = id
          row
        end

        def generate_ids(rows)
          if rows.length == 1 && omit_suffix_if_single
            rows.map { |row|
              row[id_target] = "#{prefix}#{row[id_source]}"
              row
            }
          elsif rows.length == 1
            [generate_id(rows[0], 0)]
          else
            generate_multirow_ids(rows)
          end
        end

        def generate_multirow_ids(rows)
          if sort_on
            sorted_rows(rows).map.with_index { |row, idx|
              generate_id(row, idx)
            }
          else
            rows.map.with_index { |row, idx| generate_id(row, idx) }
          end
        end

        def sorted_rows(rows)
          case sort_type
          when :date
            rows.sort_by { |row| sortable_date_from_row(row, sort_on) }
          when :i
            rows.sort_by do |row|
              val = row[sort_on]
              val.blank? ? 0 : val.to_i
            end
          else
            rows.sort_by do |row|
              val = row[sort_on]
              val.blank? ? "" : val
            end
          end
        end

        def source_deleteable?
          true unless id_source == id_target
        end
      end
    end
  end
end
