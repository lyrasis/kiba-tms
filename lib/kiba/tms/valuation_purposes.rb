# frozen_string_literal: true

module Kiba
  module Tms
    module ValuationPurposes
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable

      setting :id_field, default: :valuationpurposeid, reader: true
      setting :type_field, default: :valuationpurpose, reader: true
      setting :used_in,
        default: [
          "ObjInsurance.#{id_field}"
        ],
        reader: true

      extend Tms::Mixins::TypeLookupTable
      def default_mapping_treatment
        :self
      end
    end
  end
end
