# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module Objects
      module Cleaners
        extend Dry::Configurable
        setting :culture, default: nil, reader: true
        setting :inscribed, default: nil, reader: true
        setting :markings, default: nil, reader: true
        setting :medium, default: nil, reader: true
        setting :signed, default: nil, reader: true
      end
    end
  end
end
