# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module AssocParents
      extend Dry::Configurable
      extend Tms::Mixins::AutoConfigurable
      extend Tms::Mixins::MultiTableMergeable
      module_function

      setting :delete_fields, default: %i[complete mixed], reader: true
      setting :empty_fields, default: {}, reader: true
      setting :target_tables, default: %w[], reader: true
    end
  end
end
