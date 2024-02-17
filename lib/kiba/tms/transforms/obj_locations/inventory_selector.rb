# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ObjLocations
        class InventorySelector
          def process(row)
            tt = row[:transport_type]
            return unless tt && tt == "inventory"

            row
          end

          private
        end
      end
    end
  end
end
