# frozen_string_literal: true

module Kiba
  module Tms
    # Looks like a type lookup table, but nothing looks up from it
    # Names are extracted from it
    module LocHandlers
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable

      setting :name_fields,
        default: %i[handler],
        reader: true
      extend Tms::Mixins::UncontrolledNameCompileable
    end
  end
end
