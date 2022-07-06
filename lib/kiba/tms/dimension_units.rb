# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module DimensionUnits
      extend Dry::Configurable
      # map values in TMS table to CS measurementUnits optionlist
      setting :unit_mapping,
        default: {
          'Inches' => 'inches',
          'Centimeters' => 'centimeters',
          'Pounds' => 'pounds',
          'Kilograms' => 'kilograms',
          'Meters' => 'meters',
          'Feet' => 'feet',
        },
        reader: true
    end
  end
end
