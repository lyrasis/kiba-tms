# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module DimensionTypes
      extend Dry::Configurable
      extend Tms::Mixins::Tableable
      extend Tms::Mixins::TypeLookupTable
      module_function

      setting :delete_fields,
        default: %i[unittypeid primaryunitid secondaryunitid system],
        reader: true
      setting :empty_fields, default: {}, reader: true
      
      setting :id_field, default: :dimensiontypeid, reader: true
      setting :type_field, default: :dimensiontype, reader: true
      setting :used_in,
        default: [
          "Dimensions.#{id_field}",
          "DimElemTypeXrefs.#{id_field}"
        ],
        reader: true
      setting :mappings, default: {}, reader: true
    end
  end
end
