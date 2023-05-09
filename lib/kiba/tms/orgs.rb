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
          textentry_internal],
        reader: true
      setting :group_sources,
        default: [:culturegroup],
        reader: true
    end
  end
end
