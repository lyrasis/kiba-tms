# frozen_string_literal: true

module Kiba
  module Tms
    module TextStatuses
      extend Dry::Configurable
      module_function

      extend Tms::Mixins::Tableable

      setting :id_field, default: :textstatusid, reader: true
      setting :type_field, default: :textstatus, reader: true
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
