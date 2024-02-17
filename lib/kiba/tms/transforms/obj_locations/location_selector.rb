# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ObjLocations
        class LocationSelector
          def process(row)
            tt = row[:transport_type]

            return unless tt &&
              ["random check", "spot check"].any?(tt)

            row
          end

          private
        end
      end
    end
  end
end
