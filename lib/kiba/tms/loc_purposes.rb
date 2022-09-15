# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module LocPurposes
      extend Dry::Configurable
      extend Tms::Mixins::Tableable
      extend Tms::Mixins::TypeLookupTable
      module_function

      setting :delete_fields, default: %i[], reader: true
      setting :empty_fields, default: %i[], reader: true
      
      setting :id_field, default: :locpurposeid, reader: true
      setting :type_field, default: :locpurpose, reader: true
      setting :used_in,
        default: [
          "ObjLocations.#{id_field}"
        ],
        reader: true
      setting :mappings, default: {}, reader: true
    end
  end
end
