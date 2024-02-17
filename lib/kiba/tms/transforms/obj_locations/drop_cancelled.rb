# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ObjLocations
        # No rows with transport_status = cancelled are the current location in
        #   TMS. It looks like at least some of them were clearly errors and were
        #   marked cancelled instead of inactive
        class DropCancelled
          def process(row)
            status = row[:transport_status]
            return row if status.blank?

            return row unless status == "cancelled"
          end

          private
        end
      end
    end
  end
end
