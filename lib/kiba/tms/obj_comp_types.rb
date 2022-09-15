# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ObjCompTypes
      extend Dry::Configurable
      extend Tms::Mixins::Tableable
      extend Tms::Mixins::TypeLookupTable
      module_function

      setting :delete_fields, default: %i[comptypemnemonic], reader: true
      setting :empty_fields, default: %i[], reader: true
      
      setting :id_field, default: :objcomptypeid, reader: true
      setting :type_field, default: :objcomptype, reader: true
      setting :used_in,
        default: [
          "ObjCompSummary.#{id_field}",
          "ObjComponents.componenttype",
        ],
        reader: true
      setting :mappings,
        default: {
          'Part of an object' => 'non-separable-part',
          'Accessory' => 'separable-part'
        },
        reader: true
    end
  end
end
