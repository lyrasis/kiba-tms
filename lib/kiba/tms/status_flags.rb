# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module StatusFlags
      module_function
      extend Dry::Configurable

      setting :delete_fields, default: %i[], reader: true
      setting :empty_fields, default: {}, reader: true
      extend Tms::Mixins::Tableable

      setting :target_tables, default: %w[Objects], reader: true
      extend Tms::Mixins::MultiTableMergeable
    end
  end
end
