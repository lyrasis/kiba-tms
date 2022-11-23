# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module AltNums
      extend Dry::Configurable
      module_function

      extend Tms::Mixins::Tableable
      extend Tms::Mixins::MultiTableMergeable

      setting :initial_cleaner, default: nil, reader: true
      setting :description_cleaner, default: nil, reader: true
      setting :target_table_type_cleanup_needed,
        default: [],
        reader: true
      setting :target_table_type_cleanup_done,
        default: [],
        reader: true
    end
  end
end
