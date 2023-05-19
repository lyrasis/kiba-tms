# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module MediaPaths
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[isoffline shared displaysubfolders],
        reader: true
      extend Tms::Mixins::Tableable

      setting :id_field, default: :pathid, reader: true
      setting :type_field, default: :path, reader: true
      setting :used_in,
        default: [
          "MediaFiles.#{id_field}",
          "MediaRenditions.thumbpathid"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable

      def mappable_type?
        false
      end
    end
  end
end
