# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      class AddIncrementingValue
        # @param target [Symbol]
        def initialize(target: :increment, prefix: "")
          @target = target
          @prefix = prefix
          @val = 1
        end

        def process(row)
          row[target] = "#{prefix}#{val}"
          @val += 1
          row
        end

        private

        attr_reader :target, :prefix, :val
      end
    end
  end
end
