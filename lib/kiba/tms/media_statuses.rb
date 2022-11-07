# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module MediaStatuses
      extend Dry::Configurable
      module_function

      extend Tms::Mixins::Tableable

      setting :id_field, default: :mediastatusid, reader: true
      setting :type_field, default: :mediastatus, reader: true
      setting :used_in,
        default: [
          "MediaRenditions.#{id_field}"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable

      def mappable_type?
        false
      end
    end
  end
end
