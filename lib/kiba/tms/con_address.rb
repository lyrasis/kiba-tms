# frozen_string_literal: true

module Kiba
  module Tms
    module ConAddress
      extend Dry::Configurable
      module_function

      setting :delete_fields,
        default: %i[lastsalestaxid addressformatid islocation],
        reader: true
      setting :non_content_fields,
        default: [:conaddressid],
        reader: true
      extend Tms::Mixins::Tableable

      setting :active_mapping,
        default: {
          "0" => "Inactive address",
          "1" => "Active address"
        },
        reader: true
      # ConAddress columns to include in address value
      setting :address_fields,
        default: %i[displayname1 displayname2 streetline1 streetline2
                    streetline3 city state zipcode],
        reader: true
      # Client-specific country remappings.
      # We want to be able to generate a report of country values that don't
      #   have a clean/exact mapping to CS country values, so initial country
      #   merge into con_address__shaped merges in both the CS-mapped country
      #   code and original country value.
      # If the :countries_unmapped_before_clean report has any rows, the
      #   :origcountry values in those rows can be remapped here. The remapping
      #   should be to a textual country name that is properly handled by the
      #   kiba-extend Cspace::AddressCountry transform
      setting :country_remappings,
        default: {},
        reader: true
      # ConAddress columns that will be combined into CS addressplace1, if
      #   present
      setting :note_fields,
        default: %i[remarks],
        reader: true,
        constructor: ->(value){
          value << :addresstype if Tms::AddressTypes.used?
          value << :addressdates if dates_note
          %w[active billing mailing shipping].each do |type|
            value << type.to_sym if send("#{type}_note".to_sym)
          end
          value
        }
      setting :note_prefix,
        default: "Address note: ",
        reader: true
      setting :addressplace1_fields,
        default: %i[displayname1 displayname2],
        reader: true
      # ConAddress columns that will be combined into CS addressplace2.
      #   If no values in addressplace1_fields, the first of these becomes
      #   addressplace1
      setting :addressplace2_fields,
        default: %i[streetline1 streetline2 streetline3],
        reader: true
      setting :addressplace1_delim, default: " -- ", reader: true
      setting :addressplace2_delim, default: ", ", reader: true
      # The next four settings are whether to generate notes about address
      #   type/status, eg. "Is default mailing address". Default to no since CS
      #   doesn't have any note field associated with a given address
      setting :active_note, default: false, reader: true
      setting :billing_note, default: false, reader: true
      setting :mailing_note, default: false, reader: true
      setting :shipping_note, default: false, reader: true
      # Whether to migrate begin/end dates associated with addresses. If this
      #   is set to true, further implementation work needs to be done
      setting :dates_note, default: false, reader: true

      # What to do with address remarks:
      #  - :plain - will go into authority record's note field
      #  - :specific - will go into a note tagged with the specific address it
      #  applies to
      setting :address_remarks_handling, default: :specific, reader: true
      # whether inactive addresses are excluded from migration
      setting :omit_inactive_address, default: false, reader: true
      setting :shipping_mapping,
        default: {
          "0" => nil,
          "1" => "Is default shipping address"
        },
        reader: true
      setting :billing_mapping,
        default: {
          "0" => nil,
          "1" => "Is default billing address"
        },
        reader: true
      setting :mailing_mapping,
        default: {
          "0" => nil,
          "1" => "Is default mailing address"
        },
        reader: true
    end
  end
end
