# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Locations
        class AddLocationName
          include Kiba::Extend::Transforms::Helpers
          
          def initialize
            @delim = Tms.locations.hierarchy_delim
            @target = :location_name
          end

          def process(row)
            row[target] = nil
            
            vals = field_values(
              row: row,
              fields: %i[brief_address site room unittype unitnumber unitposition]
            )
            return row if vals.values.empty?

            locname = [
              vals[:brief_address],
              vals[:site],
              vals[:room],
              get_unit(vals),
              vals[:unitposition]
            ].compact
            return row if locname.empty?

            row[target] = locname.join(delim)
            row
          end

          private

          attr_reader :delim, :target

          def get_unit(vals)
            result = [vals[:unittype], vals[:unitnumber]].compact
            return nil if result.empty?

            result.join(' ')
          end
          
        end
      end
    end
  end
end
