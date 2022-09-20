# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ConGeoCodes
      extend Dry::Configurable
      module_function

      setting :delete_fields, default: %i[], reader: true
      setting :empty_fields, default: {}, reader: true
      extend Tms::Mixins::Tableable
      
      setting :id_field, default: :congeocodeid, reader: true
      setting :type_field, default: :congeocode, reader: true
      setting :used_in,
        default: [
          'ConGeography.geocodeid'
        ],
        reader: true
      setting :mappings, default: {}, reader: true
      extend Tms::Mixins::TypeLookupTable
    end
  end
end
