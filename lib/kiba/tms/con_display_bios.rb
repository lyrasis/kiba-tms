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
        default: Tms::Transforms::ConDisplayBios::Cleaner,
        reader: true
      setting :merger,
        default: Tms::Transforms::ConDisplayBios::Merger,
        reader: true
    end
  end
end
