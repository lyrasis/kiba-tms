# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module TextTypes
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable

      setting :id_field, default: :texttypeid, reader: true
      setting :type_field, default: :texttype, reader: true
      setting :used_in,
        default: [
          "TextEntries.#{id_field}"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable

      def default_mapping_treatment
        :downcase
      end
    end
  end
end
