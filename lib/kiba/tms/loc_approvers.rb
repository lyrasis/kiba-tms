# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    # Looks like a type lookup table, but nothing looks up from it
    # Names are extracted from it
    module LocApprovers
      extend Dry::Configurable
      module_function

      extend Tms::Mixins::Tableable

      setting :name_fields,
        default: %i[approver],
        reader: true
      extend Tms::Mixins::UncontrolledNameCompileable
    end
  end
end
