# frozen_string_literal: true

module Kiba
  module Tms
    module RefFormats
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable

      setting :id_field, default: :formatid, reader: true
      setting :type_field, default: :format, reader: true
      setting :used_in,
        default: [
          "ReferenceMaster.#{id_field}"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable

      def mappable_type?
        false
      end
    end
  end
end
