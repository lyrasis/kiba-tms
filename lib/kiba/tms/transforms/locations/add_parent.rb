# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Locations
        class AddParent
          def initialize
            @delim = Tms::Locations.hierarchy_delim
            @target = :parent_location
          end

          def process(row)
            row[target] = nil

            locname = row[:location_name]
            return row if locname.blank?

            segments = locname.split(delim)
            return row if segments.length == 1

            segments.pop
            row[target] = segments.join(delim)

            row
          end

          private

          attr_reader :delim, :target
        end
      end
    end
  end
end
