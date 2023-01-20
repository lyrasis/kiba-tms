# frozen_string_literal: true

module Kiba
  module Tms
    module ConAddress
      extend Dry::Configurable
      module_function

      setting :delete_fields,
        default: %i[conaddressid lastsalestaxid addressformatid islocation],
        reader: true
      extend Tms::Mixins::Tableable

      setting :active_mapping,
        default: {
          '0' => 'Inactive address',
          '1' => 'Active address'
        },
        reader: true
      setting :shipping_mapping,
        default: {
          '0' => nil,
          '1' => 'Is default shipping address'
        },
        reader: true
      setting :billing_mapping,
        default: {
          '0' => nil,
          '1' => 'Is default billing address'
        },
        reader: true
      setting :mailing_mapping,
        default: {
          '0' => nil,
          '1' => 'Is default mailing address'
        },
        reader: true
    end
  end
end
