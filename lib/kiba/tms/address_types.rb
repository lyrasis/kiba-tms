# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module AddressTypes
      extend Dry::Configurable
      module_function

      extend Tms::Mixins::Tableable

      setting :id_field, default: :addresstypeid, reader: true
      setting :type_field, default: :addresstype, reader: true
      setting :used_in,
        default: [
          "ConAddress.#{id_field}"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable

      def default_mapping_treatment
        :self
      end
    end
  end
end
