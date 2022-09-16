# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ConGeography
      extend Dry::Configurable
      module_function

      # whether or not table is used
      setting :used, default: ->{ Tms::Table::List.include?('ConGeography') }, reader: true
      # Fields beyond DeleteTmsFields general fields to delete
      setting :delete_fields, default: %i[keyfieldssearchvalue primarydisplay], reader: true
      setting :empty_fields, default: {}, reader: true
    end
  end
end
