# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ObjectNames
      extend Dry::Configurable
      module_function

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