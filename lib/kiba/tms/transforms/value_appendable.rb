# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      # Mix-in module
      module ValueAppendable
        # @param row [Hash{Symbol => String}]
        # @param target [Symbol]
        # @param value [String]
        # @param delim [String]
        def append_value(row, target, value, delim)
          val = target_values(row, target, delim) << value
          row[target] = val.join(delim)
        end

        private def target_values(row, target, delim)
                  vals = row[target]
                  vals.blank? ? [] : vals.split(delim)
                end
      end
    end
  end
end
