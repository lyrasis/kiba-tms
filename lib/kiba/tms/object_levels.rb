# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ObjectLevels
      extend Dry::Configurable
      module_function

      extend Tms::Mixins::Tableable

      setting :id_field, default: :objectlevelid, reader: true
      setting :type_field, default: :objectlevel, reader: true
      setting :used_in,
        default: [
          "Objects.#{id_field}"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable
    end
  end
end
