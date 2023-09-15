# frozen_string_literal: true

module Kiba
  module Tms
    module Orgs
      extend Dry::Configurable

      module_function

      # Indicates what job output to use as the base for non-TMS-table-sourced
      #   modules
      setting :source_job_key, default: :name_compile__orgs, reader: true
      extend Tms::Mixins::Tableable

      # Fields to combine into the history note field in the CS organization
      #   record. Fields are combined in the order given here. Sources for
      #   merged in notes are:
      #
      # - textentry_public, textentry_internal - TextEntries table
      # - geo_note - ConGeography table
      # - address_namenote - ConAddress table
      # - email_web_namenote - ConEmail table
      # - phone_fax_namenote - ConPhone table
      # - rel_name_bio_note - related names from compiled name data, set to
      #   map as notes
      setting :historynote_sources,
        default: %i[biography displayed_bio remarks
          textentry_public datenote geo_note
          address_namenote email_web_namenote phone_fax_namenote
          textentry_internal
          rel_name_bio_note],
        reader: true

      # Field(s) to map to the CS Organization Group field
      setting :group_sources,
        default: [:culturegroup],
        reader: true

      # TMS or intermediate field values to be mapped into CS' multi-
      #   valued, controlled organization type field
      setting :organizationrecordtype_sources,
        default: [],
        reader: true

      # Preferred source for the single valued Foundation place field.
      # Options:
      #
      # - :congeo_nationality - If a value tagged Place of Birth (or equivalent)
      #   exists for the name in the ConGeography, use the first such value.
      #   Other ConGeography values and any :nationality value present are
      #   mapped into the History note. This is the default because ConGeography
      #   actually includes place values, whereas :nationality is not a place.
      # - :congeo_only - As above, but never map :nationality field value as
      #   :foundingplace
      # - :nationality_only - Map :nationality values to :foundingplace, and
      #   treat all ConGeography values as notes.
      setting :foundingplace_handling,
        default: :congeo_nationality,
        reader: true

      # Fields to be include in repeatable Term field group for
      #   organizations
      setting :term_targets,
        default: %i[termdisplayname termflag termsourcenote],
        reader: true,
        constructor: ->(value) do
          value << :termsource if Tms::Names.set_term_source
          value << :termprefforlang if Tms::Names.set_term_pref_for_lang
          value
        end
    end
  end
end
