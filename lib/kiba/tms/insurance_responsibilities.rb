# frozen_string_literal: true

module Kiba
  module Tms
    module InsuranceResponsibilities
      extend Dry::Configurable
      module_function

      setting :delete_fields, default: %i[system], reader: true
      extend Tms::Mixins::Tableable

      setting :id_field, default: :responsibilityid, reader: true
      setting :type_field, default: :responsibility, reader: true
      setting :used_in,
        default: [
          "ExhVenuesXrefs.insurancereturn",
          "ExhVenuesXrefs.insuranceatvenue",
          "ExhVenuesXrefs.insurancefromlender",
          "ExhVenuesXrefs.insurancefrompreviousvenue",
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable

      def mappable_type?
        false
      end
    end
  end
end
