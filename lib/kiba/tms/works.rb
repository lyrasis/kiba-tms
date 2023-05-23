# frozen_string_literal: true

module Kiba
  module Tms
    module Works
      extend Dry::Configurable

      module_function

      setting :multi_source_normalizer,
        default: Kiba::Extend::Utils::MultiSourceNormalizer.new, reader: true
    end
  end
end
