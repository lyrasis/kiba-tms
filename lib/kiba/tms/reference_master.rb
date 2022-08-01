# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ReferenceMaster
      module_function
      
      extend Dry::Configurable
      # whether or not table is used
      setting :used, default: ->{ Tms::Tables::List.call.any?('ReferenceMaster') }, reader: true
      # Fields beyond DeleteTmsFields general fields to delete
      setting :delete_fields, default: %i[alphaheading sortnumber publicaccess conservationentityid], reader: true
    end
  end
end
