# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module DimensionMethods
      extend Dry::Configurable
      extend Tms::AutoConfigurable
      module_function

      setting :delete_fields, default: %i[], reader: true
      setting :empty_fields, default: %i[], reader: true
      
      setting :type_lookup, default: true, reader: true
      setting :id_field, default: :methodid, reader: true
      setting :type_field, default: :method, reader: true
      setting :used_in,
        default: [
          'DimItemElemXrefs.methodid',
        ],
        reader: true
      setting :mappings, default: {}, reader: true
    end
  end
end
