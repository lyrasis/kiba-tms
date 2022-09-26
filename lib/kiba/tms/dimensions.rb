# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module Dimensions
      extend Dry::Configurable
      module_function

      setting :delete_fields,
        default: %i[displayed dimensionid secondaryunitid],
        reader: true
      setting :empty_fields, default: {}, reader: true
      extend Tms::Mixins::Tableable
    end
  end
end
