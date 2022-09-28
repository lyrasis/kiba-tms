# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module PhoneTypes
      extend Dry::Configurable
      module_function

      extend Tms::Mixins::Tableable

      setting :id_field, default: :phonetypeid, reader: true
      setting :type_field, default: :phonetype, reader: true
      setting :used_in,
        default: [
          "ConPhones.#{id_field}"
        ],
        reader: true
      setting :mappings,
        default: {
          "Home"=>"home",
          "Cell"=>"mobile",
          "Office"=>"business"
        },
        reader: true
      extend Tms::Mixins::TypeLookupTable
    end
  end
end
