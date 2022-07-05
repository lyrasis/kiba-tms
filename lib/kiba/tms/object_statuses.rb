# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ObjectStatuses
      extend Dry::Configurable
      # map values in TMS table to InventoryStatuses vocabulary terms
      setting :inventory_status_mapping, default: {}, reader: true
    end
  end
end
