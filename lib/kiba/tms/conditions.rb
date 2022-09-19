# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module Conditions
      extend Dry::Configurable
      module_function

      setting :delete_fields, default: [], reader: true
      setting :empty_fields, default: {}, reader: true
      extend Tms::Mixins::Tableable
      
      setting :target_tables, default: %w[], reader: true
      extend Tms::Mixins::MultiTableMergeable
    end
  end
end
