# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    # Looks like a type lookup table, but nothing looks up from it
    # Names are extracted from it
    module LocHandlers
      extend Dry::Configurable
      extend Tms::Mixins::Tableable
      module_function

      setting :delete_fields, default: %i[], reader: true
      setting :empty_fields, default: {}, reader: true
    end
  end
end
