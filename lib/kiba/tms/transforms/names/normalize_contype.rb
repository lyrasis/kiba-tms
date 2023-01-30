# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Names
        class NormalizeContype
          def initialize(source: :contype, target: :contype_norm)
            @source = source
            @target = target
            @normalizer = Tms::Services::Names::ContypeNormalizer.new
          end

          # @private
          def process(row)
            row[target] = nil unless source == target
            type = row[source]
            return row if type.blank?

            row[target] = normalizer.call(type)
            row
          end

          private

          attr_reader :source, :target, :normalizer
        end
      end
    end
  end
end
