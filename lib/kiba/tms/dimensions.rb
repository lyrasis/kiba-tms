# frozen_string_literal: true

module Kiba
  module Tms
    module Dimensions
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
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
