# frozen_string_literal: true

module Kiba
  module Tms
    module ConPhones
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable

      setting :description_cleaner,
        default: nil,
        reader: true
    end
  end
end
