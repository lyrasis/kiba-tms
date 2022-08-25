# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module NameTypeCleanup
      module_function
      
      extend Dry::Configurable
      # Indicates whether any cleanup has been returned. If not, we run everything on base data. If yes, we
      #   merge in/overlay cleanup on anything using this data.
      setting :cleanup_done, default: false, reader: true
    end
  end
end

