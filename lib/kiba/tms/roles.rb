# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module Roles
      extend Dry::Configurable
      module_function

      setting :delete_fields,
        default: %i[anonymousnameid prepositional],
        reader: true
      extend Tms::Mixins::Tableable
    end
  end
end
