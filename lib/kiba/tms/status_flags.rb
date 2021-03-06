# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module StatusFlags
      extend Dry::Configurable

      setting :target_tables, default: %w[Objects], reader: true
    end
  end
end
