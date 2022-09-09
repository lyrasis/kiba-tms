# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ObjectStatuses
      extend Dry::Configurable
      extend Tms::Omittable
      module_function

      # whether or not table is used
      setting :used, default: ->{ Tms::Table::List.include?('ObjectStatuses') }, reader: true
      # Fields beyond DeleteTmsFields general fields to delete
      setting :delete_fields, default: %i[], reader: true
      setting :empty_fields, default: %i[], reader: true

      # map values in TMS table to InventoryStatuses vocabulary terms
      setting :inventory_status_mapping, default: {}, reader: true
    end
  end
end
