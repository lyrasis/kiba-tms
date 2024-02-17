# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ObjLocations
        # Removes ObjLocations rows where (:transport_type = "scheduled move to
        #   new home" or "scheduled temporary move") AND (:transport_status =
        #   "completed"
        #
        # In no case is the scheduled row marked as the current row for the
        #   object/object component. Every scheduled row is followed by a row
        #   that indicates the actual location move information that was related
        #   to the scheduled plan
        class DropScheduledComplete
          def process(row)
            return row unless scheduled?(row) && complete?(row)
          end

          private

          def complete?(row)
            status = row[:transport_status]
            return false if status.blank?

            status == "completed"
          end

          def scheduled?(row)
            type = row[:transport_type]
            return false if type.blank?

            type.start_with?("scheduled")
          end
        end
      end
    end
  end
end
