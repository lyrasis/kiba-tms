# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module AltNums
      extend Dry::Configurable
      module_function

      extend Tms::Mixins::Tableable
      extend Tms::Mixins::MultiTableMergeable

      setting :description_cleaner, default: nil, reader: true
    end
  end
end
