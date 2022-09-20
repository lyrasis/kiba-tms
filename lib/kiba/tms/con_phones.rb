# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ConPhones
      extend Dry::Configurable
      module_function

      setting :delete_fields, default: [], reader: true
      setting :empty_fields, default: {}, reader: true
      extend Tms::Mixins::Tableable
    end
  end
end
