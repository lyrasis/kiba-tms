# frozen_string_literal: true

module Kiba
  module Tms
    module Orgs
      extend Dry::Configurable

      module_function

      setting :source_job_key, default: :name_compile__orgs, reader: true
      extend Tms::Mixins::Tableable

      setting :historynote_sources,
        default: %i[biography displayed_bio remarks
          textentry_public datenote geo_note
          address_namenote email_web_namenote phone_fax_namenote
          textentry_internal
          name_rel_bio_note],
        reader: true
      setting :group_sources,
        default: [:culturegroup],
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
