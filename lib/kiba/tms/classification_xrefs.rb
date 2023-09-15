# frozen_string_literal: true

module Kiba
  module Tms
    module ClassificationXRefs
      module_function

      extend Dry::Configurable
      extend Tms::Mixins::Tableable
      extend Tms::Mixins::MultiTableMergeable
    end
  end
end
