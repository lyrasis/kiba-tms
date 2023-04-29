# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module TransCodes
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable

      setting :id_field, default: :transcodeid, reader: true
      setting :type_field, default: :transcode, reader: true
      setting :used_in,
        default: [
          "ObjLocations.#{id_field}"
          #          "ShipCrateHiers.#{id_field}"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable

      def default_mapping_treatment
        :self
      end
    end
  end
end
