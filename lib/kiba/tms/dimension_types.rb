# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module DimensionTypes
      extend Dry::Configurable
      # map values in TMS table to CS measurementUnits optionlist
      setting :type_mapping,
        default: {
          'Height' => 'height',
          'Width' => 'width',
          'Depth' => 'depth',
          'Weight' => 'weight'
        },
        reader: true
    end
  end
end
