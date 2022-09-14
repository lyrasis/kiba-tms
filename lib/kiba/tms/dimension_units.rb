# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module DimensionUnits
      extend Dry::Configurable
      extend Tms::Mixins::AutoConfigurable
      extend Tms::Mixins::TypeLookupTable
      module_function

      setting :delete_fields,
        default: %i[conversionfactor unittypeid unitlabelatend isfractional basedenominator
                    decimalplaces unitcutoff unitspersuperunit unitlabel superunitlabel
                    issuperunit system],
        reader: true
      setting :empty_fields, default: %i[], reader: true
      
      setting :id_field, default: :unitid, reader: true
      setting :type_field, default: :unitname, reader: true
      setting :used_in,
        default: [
          "Dimensions.primaryunitid",
          "Dimensions.secondaryunitid",
          "PlaceCoordinates.#{id_field}"
        ],
        reader: true
      setting :mappings, default: {}, reader: true
    end
  end
end
