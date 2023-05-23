# frozen_string_literal: true

module Kiba
  module Tms
    module HistEvents
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable
    end
  end
end
