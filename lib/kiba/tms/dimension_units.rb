# frozen_string_literal: true

module Kiba
  module Tms
    module DimensionUnits
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[unittypeid unitlabelatend isfractional
          basedenominator decimalplaces unitcutoff unitspersuperunit
          unitlabel superunitlabel issuperunit system],
        reader: true
      extend Tms::Mixins::Tableable

      setting :id_field, default: :unitid, reader: true
      setting :type_field, default: :unitname, reader: true
      setting :used_in,
        default: [
          "Dimensions.primaryunitid",
          "Dimensions.secondaryunitid",
          "PlaceCoordinates.#{id_field}"
        ],
        reader: true
      setting :mappings,
        default: {
          "Inches" => "inches",
          "Centimeters" => "centimeters",
          "Pounds" => "pounds",
          "Kilograms" => "kilograms",
          "Cubic Centimeters" => "cubic-centimeters",
          "Cubic Inches" => "cubic inches"
        },
        reader: true
      extend Tms::Mixins::TypeLookupTable

      def default_mapping_treatment
        :downcase
      end
    end
  end
end
