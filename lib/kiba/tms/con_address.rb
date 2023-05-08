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

      # Whether inactive addresses are included in migration
      #
      # Defaults to `false` because TMS tends to use "inactive" to code values
      #   that were mistakenly entered or no longer used. Setting to inactive
      #   appears to be a way of fake-deleting a value from use in the system,
      #   without removing record of the value in the database.
      setting :migrate_inactive, default: false, reader: true

      # Whether to include the value of `:active_mapping` for each row
      #   in a note about the address. This has no effect (i.e. no note
      #   is ever created) if `:migrate_inactive` = false.
      setting :active_note, default: true, reader: true

      # Provides the value of the active note, if included. Only relevant if
      #   `:migrate_inactive` = true AND `:include_active_note` = true
      setting :active_mapping,
        default: {
          "0" => "Inactive address",
          "1" => "Active address"
        },
        reader: true

      # TMS provides more address fields than does the CS data model, and every
      #   TMS institution (if not user) seems to enter address data differently,
      #   so there is some complexity in how we configure the mappings in the
      #   migration.

      # TMS ConAddress table fields to include in CS address value
      setting :address_fields,
        default: %i[displayname1 displayname2 streetline1 streetline2
          streetline3 city state zipcode],
        reader: true

      # ConAddress columns that will be combined into CS addressplace1.
      #
      # Processing note: The RemoveRedundantAddressLines transform checks the
      #   values in the fields listed here against the preferred and
      #   non-preferred form of name represented by the authority the address
      #   will be merged into. Values in these fields are deleted if they
      #   match either of the name forms. See the next setting for what happens
      #   if this transform leaves both `:addressplace1_fields` empty.
      setting :addressplace1_fields,
        default: %i[displayname1 displayname2],
        reader: true

      # ConAddress columns that will be combined into CS addressplace2.
      #
      # Note: If both :addressplace1_fields are blank, the value of the first
      #   populated field listed here becomes the value of CS addressplace1
      setting :addressplace2_fields,
        default: %i[streetline1 streetline2 streetline3],
        reader: true

      # If more than one TMS field value is combined to create CS addressplace1,
      #   this string is used to separate the two values
      setting :addressplace1_delim, default: " -- ", reader: true

      # If more than one TMS field value is combined to create CS addressplace2,
      #   this string is used to separate the values
      setting :addressplace2_delim, default: ", ", reader: true

      # ---------------------------------
      # A bunch of settings to control how the very detailed data in TMS
      #   ConAddress might be smooshed into a text string that gets mapped
      #   to Person Name Note field or Org History note field for the
      #   authority the address will be merged into
      # ---------------------------------

      # Which TMS fields should be combined into a single :address_note value
      #   per TMS ConAddress row. Conditional logic here automatically includes
      #   fields in this setting based on other settings.
      setting :note_fields,
        default: %i[],
        reader: true,
        constructor: ->(value) {
          value << :remarks if migrate_remarks
          value << :addresstypenote if Tms::AddressTypes.used? &&
            address_type_handling == :note
          value << :addressdates if dates_note
          value << :active if migrate_inactive && active_note
          %w[billing mailing shipping].each do |type|
            value << type.to_sym if send("#{type}_note".to_sym)
          end
          value
        }

      # Prefix for the set of :address_note field(s) that may be merged into
      #   a single name authority
      setting :note_prefix,
        default: "Address note(s):%CR%",
        reader: true

      # Handling of the combined note for a given ConAddress row. Note that
      #   multiple ConAddress rows may be merged into a single authority in
      #   CS. This setting defaults to :specific, so that if you have multiple
      #   addresses per name, you can tell which address the note goes with
      #   (since there is no way to add notes directly on an address itself).
      #   If you do not have multiple addresses per name, you might want to
      #   set this to :plain to reduce the length of address notes
      #
      #  - :specific - The TMS :shortname value from the row will be prepended
      #   to the value of :remarks to create the note value
      #  - :plain - The value of the :remarks field will go into authority
      #   record's note field by itself
      setting :address_note_handling, default: :specific, reader: true

      # Whether to migrate remarks field values
      setting :migrate_remarks, default: true, reader: true

      # How to map the AddressType value of the address, if AddressTypes
      #   have been used in TMS.
      # :address_type_field - Will map into the Type field of the given
      #   address. This is a static option list controlled vocabulary in CS.
      #   Pros: this is where the data really belongs. Cons: See
      # https://github.com/lyrasis/collectionspace-data-explainers/blob/main/docs/controlled_vocabulary_types.adoc#option-lists
      # :note - AddressType value will become part of address_note for the
      #   row. If you have a very large number of address types or need the
      #   ability to flexibly and expressively define address types, this may
      #   work better for you.
      setting :address_type_handling, default: :address_type_field, reader: true

      # Whether to generate notes about the address' defaultbilling status
      setting :billing_note, default: false, reader: true

      # TMS `defaultbilling` values and the note vaues they will become if
      #   `billing_note` = true
      setting :billing_mapping,
        default: {
          "0" => nil,
          "1" => "Is default billing address"
        },
        reader: true

      # Whether to generate notes about the address' defaultmailing status
      setting :mailing_note, default: false, reader: true

      # TMS `defaultmailing` values and the note vaues they will become if
      #   `mailing_note` = true
      setting :mailing_mapping,
        default: {
          "0" => nil,
          "1" => "Is default mailing address"
        },
        reader: true

      # Whether to generate notes about the address' defaultmailing status
      setting :shipping_note, default: false, reader: true

      # TMS `defaultshipping` values and the note vaues they will become if
      #   `shipping_note` = true
      setting :shipping_mapping,
        default: {
          "0" => nil,
          "1" => "Is default shipping address"
        },
        reader: true

      # Whether to migrate begin/end dates associated with addresses. This
      #   defaults to false because CS does not provide a place to record dates
      #   with specific addresses. If this is set to true, further
      #   implementation work needs to be done
      setting :dates_note, default: false, reader: true

      # ----
      # Settings below this line are more technical
      # ----

      # Client-specific country remappings.
      #
      # CS has a controlled list of country values using ISO 3166 country codes
      #
      # We want to be able to generate a report of country values that don't
      #   have a clean/exact mapping to CS country values. For this reason, the
      #   initial merge of country data in the :con_address__shaped job merges
      #   in both the CS-mapped country code and original country value.
      #
      # If the :countries_unmapped_before_clean report has any rows, the
      #   :origcountry values in those rows can be remapped here. The remapping
      #   should be to a textual country name that is properly handled by the
      #   kiba-extend Cspace::AddressCountry transform
      setting :country_remappings,
        default: {},
        reader: true
    end
  end
end
