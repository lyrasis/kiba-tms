# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module ObjCompTypes
      extend Dry::Configurable
      module_function

      setting :delete_fields, default: %i[comptypemnemonic], reader: true
      extend Tms::Mixins::Tableable

      setting :id_field, default: :objcomptypeid, reader: true
      setting :type_field, default: :objcomptype, reader: true
      setting :used_in,
        default: [
          "ObjComponents.componenttype",
        ],
        reader: true
      setting :mappings,
        default: {
          "Part of an object" => "non-separable-part",
          "Accessory" => "separable-part"
        },
        reader: true
      extend Tms::Mixins::TypeLookupTable
    end
  end
end
