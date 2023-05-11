# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Names
        class CleanExplodedId
          def initialize(target: :constituentid)
            @target = target
          end

          # @private
          def process(row)
            id = row[target]
            return row if id.blank?
            return row unless id["_exploded"]

            row[target] = id.sub(/_exploded\d+$/, "")
            row
          end

          private

          attr_reader :target
        end
      end
    end
  end
end
