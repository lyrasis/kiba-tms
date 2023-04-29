# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module ConGeoCodes
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable

      setting :id_field, default: :congeocodeid, reader: true
      setting :type_field, default: :congeocode, reader: true
      setting :used_in,
        default: [
          "ConGeography.geocodeid"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable

      def default_mapping_treatment
        :downcase
      end
    end
  end
end
