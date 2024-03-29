# frozen_string_literal: true

module Kiba
  module Tms
    module FlagLabels
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields, default: %i[flaguse important], reader: true
      extend Tms::Mixins::Tableable

      setting :id_field, default: :flagid, reader: true
      setting :type_field, default: :flaglabel, reader: true
      setting :used_in,
        default: [
          "StatusFlags.#{id_field}"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable

      def mappable_type?
        false
      end
    end
  end
end
