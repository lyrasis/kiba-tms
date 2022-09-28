# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module DimensionElements
      extend Dry::Configurable
      module_function

      setting :delete_fields,
        default: %i[displayed showelementname showdescription position showsecondaryunit],
        reader: true
      extend Tms::Mixins::Tableable

      setting :id_field, default: :elementid, reader: true
      setting :type_field, default: :element, reader: true
      setting :used_in,
        default: [
          "DimElemTypeXrefs.#{id_field}",
          "DimItemElemXrefs.#{id_field}"
        ],
        reader: true
      setting :mappings,
        default: {
          'Overall'=>'overall'
        },
        reader: true
      extend Tms::Mixins::TypeLookupTable
    end
  end
end
