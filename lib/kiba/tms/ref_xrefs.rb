# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module RefXRefs
      extend Dry::Configurable
      module_function

      extend Tms::Mixins::Tableable
      extend Tms::Mixins::MultiTableMergeable
    end
  end
end