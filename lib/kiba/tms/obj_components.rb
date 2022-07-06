# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ObjComponents
      extend Dry::Configurable
      # whether or not ObjComponents is used to record information about actual object components
      #   (sub-objects). Either way TMS provides linkage to Locations through ObjComponents
      setting :actual_components, default: false, reader: true
    end
  end
end
