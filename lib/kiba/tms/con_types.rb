# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ConTypes
      extend Dry::Configurable
      extend Tms::Mixins::AutoConfigurable
      extend Tms::Mixins::TypeLookupTable
      module_function

      setting :delete_fields, default: %i[], reader: true
      setting :empty_fields, default: %i[], reader: true
      
      setting :id_field, default: :constituenttypeid, reader: true
      setting :type_field, default: :constituenttype, reader: true
      setting :used_in,
        default: [
          "Constituents.#{id_field}"
        ],
        reader: true
      setting :mappings,
        default: {
          'Business' => 'Organization',
          'Individual' => 'Person',
          'Foundation' => 'Organization',
          'Institution' => 'Organization',
          'Organization' => 'Organization',
          'Venue' => 'Organization'
        },
        reader: true
    end
  end
end
