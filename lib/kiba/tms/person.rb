# frozen_string_literal: true

module Kiba
  module Tms
    module Person
      extend Dry::Configurable
      module_function

      setting :source_job_key, default: :name_compile__persons, reader: true
      extend Tms::Mixins::Tableable

      setting :bionote_sources,
        default: [],
        reader: true
      setting :namenote_sources,
        default: [],
        reader: true
    end
  end
end
