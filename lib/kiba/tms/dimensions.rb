# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module Dimensions
      extend Dry::Configurable

      module_function

      setting :delete_fields,
        default: %i[displayed dimensionid],
        reader: true
      extend Tms::Mixins::Tableable

      setting :migrate_secondary_unit_vals,
        default: true,
        reader: true
    end
  end
end
