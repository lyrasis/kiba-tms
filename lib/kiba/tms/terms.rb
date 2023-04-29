# frozen_string_literal: true

module Kiba
  module Tms
    module Terms
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable
    end
  end
end
