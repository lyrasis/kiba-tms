# frozen_string_literal: true

module Kiba
  module Tms
    module Acquisitions
      extend Dry::Configurable

      module_function

      setting :multisource_normalizer,
        default: Kiba::Extend::Utils::MultiSourceNormalizer.new,
        reader: true
    end
  end
end
