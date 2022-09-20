# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module OverallConditions
      extend Dry::Configurable
      module_function

      setting :delete_fields, default: %i[], reader: true
      setting :empty_fields, default: {}, reader: true
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
          "Excellent"=>"excellent",
          "Fair"=>"fair",
          "Good"=>"good",
          "Poor"=>"poor",
          "Very Good"=>"very good"
        },
        reader: true
      extend Tms::Mixins::TypeLookupTable

      setting :target_tables, default: %w[Objects], reader: true
      extend Tms::Mixins::MultiTableMergeable

      def default_mapping_treatment
        :downcase
      end
    end
  end
end
