# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Objects
        class Objectcount
          def initialize
            @target = :objectcount
          end

          def process(row)
            val = row[target]
            row[target] = nil if val == "0"
            row
          end

          private

          attr_reader :target
        end
      end
    end
  end
end
