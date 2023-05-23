# frozen_string_literal: true

module Kiba
  module Tms
    module Countries
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields, default: %i[defaultaddrformatid],
        reader: true
      extend Tms::Mixins::Tableable

      setting :id_field, default: :countryid, reader: true
      setting :type_field, default: :country, reader: true
      setting :used_in,
        default: [
          "ConAddress.#{id_field}"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable

      def mappable_type?
        false
      end

      def post_transforms
        [
          Kiba::Extend::Transforms::Rename::Field.new(
            from: :country,
            to: :orig_country
          ),
          Kiba::Extend::Transforms::Cspace::AddressCountry.new(
            source: :orig_country,
            target: :country,
            keep_orig: true
          )
        ]
      end
    end
  end
end
