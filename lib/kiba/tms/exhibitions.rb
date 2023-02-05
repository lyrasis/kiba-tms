# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module Exhibitions
      extend Dry::Configurable
      module_function

      setting :delete_fields,
        default: %i[exhmnemonic],
        reader: true
      extend Tms::Mixins::Tableable
    end
  end
end
