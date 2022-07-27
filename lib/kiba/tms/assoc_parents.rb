# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module AssocParents
      extend Dry::Configurable
      # whether or not table is used
      setting :used, default: ->{ Tms.excluded_tables.none?('AssocParents') }, reader: true
      # Fields beyond DeleteTmsFields general fields to delete
      setting :delete_fields, default: %i[complete mixed], reader: true
      setting :for_constituents, default: false, reader: true
    end
  end
end
