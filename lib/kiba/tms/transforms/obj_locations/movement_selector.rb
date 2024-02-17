# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ObjLocations
        class MovementSelector
          def process(row)
            tt = row[:transport_type]

            return if tt &&
              ["inventory", "random check", "spot check"].any?(tt)

            row
          end
        end
      end
    end
  end
end
