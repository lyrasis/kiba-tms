# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module AccessionMethods
      extend Dry::Configurable
      extend Tms::Omittable
      # whether or not table is used
      setting :used, default: ->{ Tms::Table::List.include?('AccessionMethods') }, reader: true
      # Fields beyond DeleteTmsFields general fields to delete
      setting :delete_fields, default: %i[], reader: true
      setting :empty_fields, default: %i[], reader: true
      setting :mappings, default: {}, reader: true
      setting :unused_values, default: [], reader: true
    end
  end
end
