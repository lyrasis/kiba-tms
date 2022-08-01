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
      # Used to pass text entry lookup to text_entry_merger if applicable
      setting :text_entry_lookup, default: {}, reader: true
      # Custom transform to merge in text entries
      setting :text_entry_merger, default: nil, reader: true
    end
  end
end
