# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ConGeoCodes
      extend Dry::Configurable
      module_function

      # whether or not table is used
      setting :used, default: ->{ Tms::Table::List.include?('ConGeoCodes') }, reader: true
      # Fields beyond DeleteTmsFields general fields to delete
      setting :delete_fields, default: %i[], reader: true
    end
  end
end
