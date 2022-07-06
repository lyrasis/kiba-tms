# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module DimensionElements
      extend Dry::Configurable
      # map values in TMS table to CS measurementUnits optionlist
      setting :element_mapping,
        default: {
          'Other' => 'other',
          'Overall' => 'overall',
          'Storage' => 'storage'
        },
        reader: true
    end
  end
end
