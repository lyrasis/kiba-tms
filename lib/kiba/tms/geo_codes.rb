# frozen_string_literal: true

module Kiba
  module Tms
    module GeoCodes
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable

      setting :id_field, default: :geocodeid, reader: true
      setting :type_field, default: :geocode, reader: true
      setting :used_in,
        default: [
          "ObjGeography.geocodeid"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable

      def default_mapping_treatment
        :downcase
      end
    end
  end
end
