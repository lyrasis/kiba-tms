# frozen_string_literal: true

module Kiba
  module Tms
    module DimItemElemXrefs
      extend Dry::Configurable

      module_function

      setting :delete_fields,
        default: %i[displayed],
        reader: true
      extend Tms::Mixins::Tableable
      extend Tms::Mixins::MultiTableMergeable
    end
  end
end
