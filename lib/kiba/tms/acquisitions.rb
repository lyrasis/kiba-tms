# frozen_string_literal: true

require "dry-configurable"

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
