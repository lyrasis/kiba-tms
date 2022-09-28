# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module DimensionMethods
      extend Dry::Configurable
      module_function

      extend Tms::Mixins::Tableable

      setting :id_field, default: :methodid, reader: true
      setting :type_field, default: :method, reader: true
      setting :used_in,
        default: [
          'DimItemElemXrefs.methodid',
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable
    end
  end
end
