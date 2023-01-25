# frozen_string_literal: true

module Kiba
  module Tms
    module ConDisplayBios
      extend Dry::Configurable
      module_function

      extend Tms::Mixins::Tableable

      setting :migrate_inactive, default: true, reader: true
      setting :migrate_non_displayed, default: true, reader: true
      # Clean/reshape table data prior to merge
      setting :cleaner,
        default: nil,
        reader: true
      setting :merger,
        default: nil,
        reader: true
    end
  end
end
