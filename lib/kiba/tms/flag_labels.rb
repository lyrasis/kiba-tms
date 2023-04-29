# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module FlagLabels
      extend Dry::Configurable

      module_function

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
    end
  end
end
