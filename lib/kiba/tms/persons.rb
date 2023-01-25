# frozen_string_literal: true

module Kiba
  module Tms
    module Persons
      extend Dry::Configurable
      module_function

      setting :source_job_key, default: :name_compile__persons, reader: true
      extend Tms::Mixins::Tableable

      setting :bionote_sources,
        default: [],
        reader: true
      setting :group_sources,
        default: [:culturegroup],
        reader: true
      setting :namenote_sources,
        default: [],
        reader: true
    end
  end
end
