# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module Loansin
      extend Dry::Configurable
      module_function
      
      # whether or not table is used
      setting :used, default: true, reader: true
    end
  end
end
