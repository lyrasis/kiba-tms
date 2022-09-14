# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module AltNums
      extend Dry::Configurable
      extend Tms::Mixins::AutoConfigurable
      extend Tms::Mixins::MultiTableMergeable
      module_function

      setting :delete_fields, default: %i[], reader: true
      setting :empty_fields, default: {}, reader: true

      setting :target_tables, default: %w[Objects], reader: true
      setting :description_cleaner, default: nil, reader: true
    end
  end
end
