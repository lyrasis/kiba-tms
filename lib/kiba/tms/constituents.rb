# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    # config settings for handling data from the following tables:
    #   ConAddress, ConAltNames, ConDates, ConEMail, ConTypes, Constituents
    module Constituents
      extend Dry::Configurable
      module_function

      # the final 3 date fields are deleted because they are handled in the
      #   Constituents::CleanDates job (a dependency of ConDates::ToMerge job)
      setting :delete_fields,
        default: %i[lastsoundex firstsoundex institutionsoundex n_displayname
                    n_displaydate begindate enddate systemflag internalstatus
                    islocked publicaccess
                    displaydate begindateiso enddateiso],
        reader: true
      extend Tms::Mixins::Tableable


      # transform run at the beginning of prep__constituents to force
      #   client-specific changes to TMS source data
      setting :prep_transform_pre, default: nil, reader: true
      # field to use as initial/preferred form
      setting :preferred_name_field, default: :displayname, reader: true
      # Field to use as variant form of name (if :include_flipped_as_variant
      #   is true
      setting :var_name_field, default: :alphasort, reader: true
      # Whether to retain value in :var_name_field as a variant name in CS
      #   person/org record
      setting :include_flipped_as_variant, default: false, reader: true

      # Fields to retain in :constituents__by_* jobs. These jobs are for use in
      #   name compilation process. The resulting tables should not be used as
      #   sources for lookup of final, authorized forms of names
      setting :lookup_job_fields,
        default: %i[constituentid norm contype combined],
        reader: true,
        constructor: proc{ |value| value << preferred_name_field }

      # map these boolean, coded fields to text note values?
      # IF a client wants these true, then you need to do work
      setting :map_approved, default: false, reader: true
      setting :map_active, default: false, reader: true
      setting :map_isstaff, default: false, reader: true
      setting :map_isprivate, default: false, reader: true

      # The following are useful if there are duplicate preferred names that
      #   have different date values that can disambiguate the names. Note that
      #   this refers to date fields in the Constituents table or merged into
      #   such during its prep. It does not control anything about processing
      #   the ConDates table. These settings are used by the
      #   Constituents::AppendDatesToNames transform.
      setting :date_append, reader: true do
        # constituenttype values to add dates to. Should be one of:
        #
        # - :none - no dates will be added to constituent preferred names
        # - :all - will add available dates to all constituent preferred names
        # - :duplicate - will add available dates to any Person/Org constituent
        #   preferred names that are duplicates when normalized
        # - :person - will add available dates to all Person constituent
        #   preferred names
        # - :org  - will add available dates to all Organization constituent
        #   preferred names
        setting :to_type, default: :duplicate, reader: true
        # String that will separate the two dates. Will be appended to start
        #   date if there is no end date. Will be prepended to end date if there
        #   is no start date.
        setting :date_sep, default: ' - ', reader: true
        # String that will be inserted between name and prepared date value. Any
        #   punctuation that should open the wrapping of the date value should
        #   be included here.
        setting :name_date_sep, default: ', (', reader: true
        # String that will be appended to the end of result, closing the date
        #   value
        setting :date_suffix, default: ')', reader: true
      end

      # ## :constituents__clean_dates options
      #
      # List of client-specific custom transforms that should be applied to
      #   :displaydate field by :constituents__clean_dates
      setting :displaydate_cleaners,
        default: [
        ],
        reader: true
      # Patterns that will be deleted from beginning of :displaydate values.
      #   Each is converted into a regular expression for find/replace
      setting :displaydate_deletable_prefixes, default: [], reader: true


      # config for processing ConAltNames table
      setting :altnames, reader: true do
        # alt names to treat as anonymous - used by ConAltNames::QualifyAnonymous transform
        setting :consider_anonymous, default: ['anonymous'], reader: true
        # whether to run ConAltNames::QualifyAnonymous transform
        setting :qualify_anonymous, default: true, reader: true
      end

      # config for processing ConDates table
      setting :dates, reader: true do
        # whether there is constituent date data to be merged into Constituents
        # set to false if running con_dates__to_merge results in an empty table
        setting :merging, default: true, reader: true
        setting :multisource_normalizer, default: Kiba::Extend::Utils::MultiSourceNormalizer.new, reader: true
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

      def initial_headers
          base = [:constituentid, :constituenttype, :derivedcontype, :contype, preferred_name_field]
          base << var_name_field if Tms::Constituents.include_flipped_as_variant
          %i[nametitle firstname middlename lastname suffix birth_foundation_date death_dissolution_date datenote
             institution position inconsistent_org_names].each do |field|
            base << field
          end
          base
      end
    end
  end
end
