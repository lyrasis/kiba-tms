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
      #   can disambiguate the names. Note that this refers to date fields in the Constituents table or
      #   merged into such during its prep. It does not control anything about processing ConDates
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
      # config for processing ConDates table
      setting :dates, reader: true do
        # custom transform to clean up remarks before any other processing
        setting :initial_remarks_cleaner, default: nil, reader: true
        setting :known_types, default: %w[birth death active], reader: true
        setting :cleaners, default: [], reader: true
        setting :warning_generators,
          default: [
            Tms::Transforms::ConDates::WarnNoDateValue,
            Tms::Transforms::ConDates::WarnDateRangeValue,
            Tms::Transforms::ConDates::WarnNoDateType,
            Tms::Transforms::ConDates::WarnUnknownDateType,
            Tms::Transforms::ConDates::WarnMultiBirthDeathDate
          ],
          reader: true
        # used by DateFromRemarkStartingWithYr transform
        setting :yr_remark_start, default: '^(\d{4}|\d{1,2}(\/|-))', reader: true
        # used by ActiveDateFromRemarks transform
        setting :active_remark_match, default: Regexp.new('^active', Regexp::IGNORECASE), reader: true
        setting :active_remark_clean_match, default: Regexp.new('^active ', Regexp::IGNORECASE), reader: true
        # used by DateFromRemarkStartWithPartialInd transform
        setting :partial_date_indicators,
          default: %w[after approximately around before c. ca. circa],
          reader: true
        # used by MakeDatedescriptionConsistent and DateFromDatedescRemarkCombo transforms
        # should have one key per :known_types element
        # value should be array of variants (including the expected term)
        setting :datedescription_variants,
          default: {
            'active' => ['active', 'active dates', 'fl.', 'flourished'],
            'birth' => ['b.', 'birth', 'birth date', 'birth year', 'birthdate', 'birthday', 'birthplace', 'born', 'founded'],
            'death' => ['d.', 'dead', 'death', 'death date', 'death day', 'death year', 'deathdate', 'deathday', 'died']
          },
          reader: true
        # Transform that creates a date-related note (in :datenote field) mergeable into Person/Org record
        setting :note_creator, default: Tms::Transforms::ConDates::NoteCreator, reader: true
        # Transform that adds parsed date columns and warnings about date values that cannot be parsed
        setting :date_parser, default: Tms::Transforms::ConDates::DateParser, reader: true
      end
    end
  end
end
