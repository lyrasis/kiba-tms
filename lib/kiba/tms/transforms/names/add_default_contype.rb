# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Names
        class AddDefaultContype
          def initialize(target: :contype)
            @target = target
            @default = Tms::Constituents.untyped_default
          end

          # @private
          def process(row)
            type = row[target]
            return row unless type.blank?

            row[target] = default
            row
          end

          private

          attr_reader :target, :default
        end
      end
    end
  end
end
