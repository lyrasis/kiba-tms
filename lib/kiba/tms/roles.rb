# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module Roles
      extend Dry::Configurable
      extend Tms::Mixins::Tableable
      extend Tms::Mixins::TypeLookupTable
      module_function

      setting :delete_fields, default: %i[anonymousnameid prepositional], reader: true
      setting :empty_fields, default: {}, reader: true
      
      setting :id_field, default: :roleid, reader: true
      setting :type_field, default: :role, reader: true
      setting :used_in,
        default: [
          "ConRefs.#{id_field}"
        ],
        reader: true
      setting :mappings, default: {}, reader: true
    end
  end
end
