# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ObjectNameTypes
      extend Dry::Configurable
      module_function

      extend Tms::Mixins::Tableable

      setting :id_field, default: :objectnametypeid, reader: true
      setting :type_field, default: :objectnametype, reader: true
      setting :used_in,
        default: [
          "ObjectNames.#{id_field}"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable

    end
  end
end
