# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module InsuranceResponsibilities
      extend Dry::Configurable
      extend Tms::Mixins::Tableable
      extend Tms::Mixins::TypeLookupTable
      module_function

      setting :delete_fields, default: %i[system], reader: true
      setting :empty_fields, default: {}, reader: true
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
      setting :mappings, default: {}, reader: true
    end
  end
end
