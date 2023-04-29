# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameCompile
        # Mixin module to ensure all rows emitted by a transform have the same fields
        #
        # ## Implementation notes
        #
        # Classes mixing this module in should define `@rows = []` in constructor. `:rows` must
        #   be an `attr_reader`. The `:process` method should push rows to `:rows` and end by
        #   returning nil.
        module RowEvenable
          def close
            fields = rows.map(&:keys).flatten.uniq
            rows.each { |row| even(row, fields) }
            rows.each { |row| yield row }
          end

          private def even(row, fields)
            missing = fields - row.keys
            missing.each { |field| row[field] = nil }
          end
        end
      end
    end
  end
end
