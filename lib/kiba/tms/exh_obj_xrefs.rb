# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ExhObjXrefs
      extend Dry::Configurable
      module_function

      setting :delete_fields,
        default: %i[],
        reader: true
      extend Tms::Mixins::Tableable
    end
  end
end
