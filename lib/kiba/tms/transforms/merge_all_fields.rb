# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      class MergeAllFields
        def initialize(keycolumn:, lookup_jobkey:, lookup_column:,
          field_prefix: "")
          @keycolumn = keycolumn
          @lookup_column = lookup_column
          @lookup = Tms.get_lookup(
            jobkey: lookup_jobkey,
            column: lookup_column
          )
          @prefix = field_prefix
        end

        def process(row)
          val = row[keycolumn]
          return row if val.blank?

          mergerows = lookup[val]
          return row if mergerows.blank?

          merge_rows(row, mergerows)
          row
        end

        private

        attr_reader :keycolumn, :lookup_column, :lookup, :prefix

        def merge_rows(row, mergerows)
          if mergerows.length > 1
            warn("Merging only the first matching lookup row")
          end
          mergerow = mergerows.first
          mergerow.delete(lookup_column)
          prefixed = mergerow.compact
            .transform_keys { |key| "#{prefix}_#{key}".to_sym }
          row.merge!(prefixed)
        end
      end
    end
  end
end
