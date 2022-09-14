# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module AccessionLot
      extend Dry::Configurable
      extend Tms::Mixins::AutoConfigurable
      module_function

      setting :delete_fields, default: %i[], reader: true
      setting :empty_fields, default: %i[], reader: true
    end
  end
end
