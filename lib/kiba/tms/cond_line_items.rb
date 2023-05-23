# frozen_string_literal: true

module Kiba
  module Tms
    module CondLineItems
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable

      # :attributetype values from which Conservation records should
      #   also be produced (e.g. "repair")
      setting :conservation_attribute_types, default: [], reader: true
    end
  end
end
