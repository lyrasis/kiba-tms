# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module MediaTypes
      extend Dry::Configurable
      extend Tms::Mixins::Tableable
      extend Tms::Mixins::TypeLookupTable
      module_function

      setting :delete_fields, default: %i[isdigital], reader: true
      setting :empty_fields, default: {}, reader: true
      
      setting :id_field, default: :mediatypeid, reader: true
      setting :type_field, default: :mediatype, reader: true
      setting :used_in,
        default: [
          "MediaRenditions.#{id_field}"
        ],
        reader: true
      setting :mappings, default: {}, reader: true
    end
  end
end
