# frozen_string_literal: true

module Kiba
  module Tms
    module Persons
      extend Dry::Configurable

      module_function

      setting :source_job_key, default: :name_compile__persons, reader: true
      extend Tms::Mixins::Tableable

      setting :bionote_sources,
        default: %i[biography rel_name_bio_note],
        reader: true
      setting :group_sources,
        default: [:culturegroup],
        reader: true
      setting :namenote_sources,
        default: %i[remarks address_namenote email_web_namenote
          phone_fax_namenote text_entry],
        reader: true
    end
  end
end
