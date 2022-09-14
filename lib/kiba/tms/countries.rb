# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module Countries
      extend Dry::Configurable
      extend Tms::Mixins::AutoConfigurable
      extend Tms::Mixins::TypeLookupTable
      module_function

      setting :delete_fields, default: %i[], reader: true
      setting :empty_fields, default: %i[], reader: true
      
      setting :id_field, default: :countryid, reader: true
      setting :type_field, default: :country, reader: true
      setting :used_in,
        default: [
          "ConAddress.#{id_field}"
        ],
        reader: true
      setting :mappings, default: {}, reader: true
    end
  end
end
