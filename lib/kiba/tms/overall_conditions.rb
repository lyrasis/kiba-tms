# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module OverallConditions
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable

      setting :id_field, default: :overallconditionid, reader: true
      setting :type_field, default: :overallcondition, reader: true
      setting :used_in,
        default: [
          "Conditions.#{id_field}"
        ],
        reader: true
      setting :mappings,
        default: {
          "Excellent" => "excellent",
          "Fair" => "fair",
          "Good" => "good",
          "Poor" => "poor",
          "Very Good" => "very good"
        },
        reader: true
      extend Tms::Mixins::TypeLookupTable

      def default_mapping_treatment
        :downcase
      end
    end
  end
end
