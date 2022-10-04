# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ValuationControl
      extend Dry::Configurable
      module_function

      setting :multi_source_normalizer,
        default: Kiba::Extend::Utils::MultiSourceNormalizer.new,
        reader: true
    end
  end
end
