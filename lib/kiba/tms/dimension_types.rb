# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module DimensionTypes
      extend Dry::Configurable
      module_function

      setting :delete_fields,
        default: %i[unittypeid primaryunitid secondaryunitid system],
        reader: true
      setting :empty_fields, default: {}, reader: true
      extend Tms::Mixins::Tableable
      
      setting :id_field, default: :dimensiontypeid, reader: true
      setting :type_field, default: :dimensiontype, reader: true
      setting :used_in,
        default: [
          "Dimensions.#{id_field}",
          "DimElemTypeXrefs.#{id_field}"
        ],
        reader: true
      setting :mappings,
        default: {
          "Height"=>"height",
          "Width"=>"width",
          "Depth"=>"depth",
          "Weight"=>"weight"
        },
        reader: true
      extend Tms::Mixins::TypeLookupTable

      def default_mapping_treatment
        :downcase
      end
    end
  end
end
