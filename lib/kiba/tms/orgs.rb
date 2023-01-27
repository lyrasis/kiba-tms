# frozen_string_literal: true

module Kiba
  module Tms
    module Orgs
      extend Dry::Configurable
      module_function

      setting :source_job_key, default: :name_compile__orgs, reader: true
      extend Tms::Mixins::Tableable

      setting :historynote_sources,
        default: [],
        reader: true
      setting :group_sources,
        default: [:culturegroup],
        reader: true
    end
  end
end
