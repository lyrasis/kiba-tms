# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module Currencies
      extend Dry::Configurable
      module_function

      setting :delete_fields,
        default: %i[localeid currencycode iseuro numberofdecimals
                    replacedbycurrencyid replacementrate replacedonisodate
                    allowedforlocalvalues],
        reader: true
      extend Tms::Mixins::Tableable

      setting :id_field, default: :currencyid, reader: true
      setting :type_field, default: :currency, reader: true
      setting :used_in,
        default: [
          "InsurancePolicies.#{id_field}",
          "ObjAccession.#{id_field}",
          "ObjInsurance.#{id_field}",
          "ObjInsurance.localcurrencyid"
        ],
        reader: true
      setting :mappings,
        default: {
          "US $" => "US Dollar"
        },
        reader: true
      extend Tms::Mixins::TypeLookupTable
    end
  end
end
