# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Locations
        class AddLocationName
          include Kiba::Extend::Transforms::Helpers

          def initialize
            @delim = Tms::Locations.hierarchy_delim
            @target = :location_name
            @fields = Tms::Locations.loc_fields
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: fields
            )
          end

          def process(row)
            row[target] = nil

            vals = getter.call(row)
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

          attr_reader :delim, :target, :fields, :getter

          def get_unit(vals)
            result = %i[unittype unitnumber].select { |src| fields.any?(src) }
              .map { |src| vals[src] }
              .compact
            return nil if result.empty?

            result.join(" ")
          end
        end
      end
    end
  end
end
