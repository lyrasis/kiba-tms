# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module DimensionMethods
      extend Dry::Configurable
      # whether or not table is used
      setting :used, default: ->{ Tms.excluded_tables.none?('DimensionMethods.csv') }, reader: true
      # # map values in TMS table to CS measurementUnits optionlist
      # setting :type_mapping,
      #   default: {
      #     'Height' => 'height',
      #     'Width' => 'width',
      #     'Depth' => 'depth',
      #     'Weight' => 'weight'
      #   },
      #   reader: true
    end
  end
end
