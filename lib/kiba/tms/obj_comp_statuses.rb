# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module ObjCompStatuses
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[compstatforecolor compstatbackcolor available system
          systemid],
        reader: true
      extend Tms::Mixins::Tableable

      setting :id_field, default: :objcompstatusid, reader: true
      setting :type_field, default: :objcompstatus, reader: true
      setting :used_in,
        default: [
          "ObjComponents.#{id_field}"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable
    end
  end
end
