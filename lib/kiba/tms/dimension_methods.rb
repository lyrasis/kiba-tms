# frozen_string_literal: true

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
          "DimItemElemXrefs.methodid"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable

      def default_mapping_treatment = :downcase
    end
  end
end
