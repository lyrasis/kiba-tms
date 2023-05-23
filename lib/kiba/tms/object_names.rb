# frozen_string_literal: true

module Kiba
  module Tms
    module ObjectNames
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[objectnameid],
        reader: true
      extend Tms::Mixins::Tableable

      setting :migrate_inactive,
        default: true,
        reader: true
    end
  end
end
