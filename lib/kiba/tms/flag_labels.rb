# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module FlagLabels
      extend Dry::Configurable
      extend Tms::Mixins::MultiTableMergeable
      extend Tms::Mixins::Tableable
      extend Tms::Mixins::TypeLookupTable
      module_function

      setting :delete_fields, default: %i[flaguse important], reader: true
      setting :empty_fields, default: %i[], reader: true
      
      setting :id_field, default: :flagid, reader: true
      setting :type_field, default: :flaglabel, reader: true
      setting :used_in,
        default: [
          "StatusFlags.#{id_field}"
        ],
        reader: true
      setting :mappings, default: {}, reader: true
    end
  end
end
