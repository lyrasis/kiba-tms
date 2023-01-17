# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module Sites
      extend Dry::Configurable
      module_function

      extend Tms::Mixins::Tableable
    end
  end
end