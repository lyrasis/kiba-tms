# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module AssocParents
      extend Dry::Configurable

      module_function

      setting :delete_fields, default: %i[complete mixed], reader: true
      extend Tms::Mixins::Tableable
      extend Tms::Mixins::MultiTableMergeable
    end
  end
end
