# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    # config settings for handling data from the following tables:
    #   ConAddress, ConAltNames, ConDates, ConEMail, ConPhones, ConTypes, Constituents
    module Constituents
      extend Dry::Configurable

      # transform run at the beginning of prep__constituents to force client-specific changes
      setting :prep_transform_pre, default: nil, reader: true
      # field to use as initial/preferred form
      setting :preferred_name_field, default: :displayname, reader: true
      # field to use as alt form
      setting :var_name_field, default: :alphasort, reader: true
      setting :include_flipped_as_variant, default: true, reader: true
      # map these boolean, coded fields to text note values?
      # IF a client wants these true, then you need to do work
      setting :map_approved, default: false, reader: true
      setting :map_active, default: false, reader: true
      setting :map_isstaff, default: false, reader: true
      setting :map_isprivate, default: false, reader: true
      # what cs field to map :culturegroup into
      setting :culturegroup_target, default: :group, reader: true
      # inactive addresses are excluded from migration
      setting :omit_inactive_address, default: false, reader: true
      # ConAddress columns to include in address value
      setting :address_fields,
        default: %i[displayname1 displayname2 streetline1 streetline2 streetline3 city state zipcode],
        reader: true
      # ConAddress columns that will be combined into CS addressplace1, if present
      setting :addressplace1_fields,
        default: %i[displayname1 displayname2],
        reader: true
      # ConAddress columns that will be combined into CS addressplace2.
      # If no values in addressplace1_fields, the first of these becomes addressplace1
      setting :addressplace2_fields,
        default: %i[streetline1 streetline2 streetline3],
        reader: true
      setting :addressplace1_delim, default: ' -- ', reader: true
      setting :addressplace2_delim, default: ', ', reader: true
      # The next four settings are whether to generate notes about address type/status, eg. "Is
      # default mailing address". Default to no since CS doesn't have any note field associated with
      # a given address
      setting :address_shipping, default: false, reader: true
      setting :address_billing, default: false, reader: true
      setting :address_mailing, default: false, reader: true
      setting :address_active, default: false, reader: true
      setting :address_dates, default: false, reader: true
      # What to do with address remarks:
      #  - :plain - will go into authority record's note field
      #  - :specific - will go into a note tagged with the specific address it applies to
      setting :address_remarks_handling, default: :specific, reader: true
      # The following are useful if there are duplicate preferred names that have different date values that
      #   can disambiguate the names
      setting :date_append, reader: true do
        # constituenttype values to add dates to. Should be: [:all], [:none], or Array of String values
        setting :to_types, default: [:all], reader: true
        # String that will separate the two dates. Will be appended to start date if there is no end date.
        #   Will be prepended to end date if there is no start date.
        setting :date_sep, default: ' - ', reader: true
        # String that will be inserted between name and prepared date value. Any punctuation that should open
        #   the wrapping of the date value should be included here.
        setting :name_date_sep, default: ', (', reader: true
        # String that will be appended to the end of result, closing the date value
        setting :date_suffix, default: ')', reader: true
      end
    end
  end
end
