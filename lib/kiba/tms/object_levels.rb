# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ObjectLevels
      extend Dry::Configurable
      extend Tms::Mixins::AutoConfigurable
      module_function

      setting :delete_fields, default: %i[], reader: true
      setting :empty_fields, default: %i[], reader: true
      
      setting :type_lookup, default: true, reader: true
      setting :id_field, default: :objectlevelid, reader: true
      setting :type_field, default: :objectlevel, reader: true
      setting :used_in,
        default: [
          "Objects.#{id_field}"
        ],
        reader: true
      setting :mappings, default: {}, reader: true
    end
  end
end
