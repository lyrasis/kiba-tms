# frozen_string_literal: true

module Kiba
  module Tms
    module DimItemElemXrefs
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[displayed],
        reader: true
      extend Tms::Mixins::Tableable

      setting :type_field,
        default: :element,
        reader: true
      extend Tms::Mixins::MultiTableMergeable
    end
  end
end
