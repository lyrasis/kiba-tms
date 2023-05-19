# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module MediaTypes
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields, default: %i[isdigital], reader: true
      extend Tms::Mixins::Tableable

      setting :id_field, default: :mediatypeid, reader: true
      setting :type_field, default: :mediatype, reader: true
      setting :used_in,
        default: [
          "MediaRenditions.#{id_field}"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable
    end
  end
end
