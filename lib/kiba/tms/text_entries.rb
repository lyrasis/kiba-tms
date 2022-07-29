# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module TextEntries
      module_function
      extend Dry::Configurable
      # whether or not table is used
      setting :used, default: ->{ Tms.excluded_tables.none?('TextEntries') }, reader: true
      # Fields beyond DeleteTmsFields general fields to delete
      setting :delete_fields, default: %i[complete mixed], reader: true
      setting :target_tables, default: [], reader: true
      # pass in client-specific transform classes to prepare text_entry rows for merging
      setting :for_object_transform, default: nil, reader: true
    end
  end
end
