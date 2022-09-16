# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module DimensionElements
      extend Dry::Configurable
      extend Tms::Mixins::Tableable
      extend Tms::Mixins::TypeLookupTable
      module_function

      setting :delete_fields,
        default: %i[displayed showelementname showdescription position showsecondaryunit],
        reader: true
      setting :empty_fields, default: {}, reader: true
      
      setting :id_field, default: :elementid, reader: true
      setting :type_field, default: :element, reader: true
      setting :used_in,
        default: [
          "DimElemTypeXrefs.#{id_field}",
          "DimItemElemXrefs.#{id_field}"
        ],
        reader: true
      setting :mappings, default: {}, reader: true
    end
  end
end
