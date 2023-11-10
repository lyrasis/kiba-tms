# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Dimensions
        class DeleteSecondaryUnitVals
          def initialize(field:)
            @target = field
            @pattern = / \(.*\)$/
          end

          def process(row)
            val = row[target]
            return row unless val.match?(pattern)

            row[target] = val.sub(pattern, "")
            row
          end

          private

          attr_reader :target, :pattern
        end
      end
    end
  end
end
