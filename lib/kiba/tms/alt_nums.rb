# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module AltNums
      extend Dry::Configurable

      module_function
      
      setting :target_tables, default: %w[Objects], reader: true
      setting :description_cleaner, default: nil, reader: true
    end
  end
end
