# frozen_string_literal: true

module Kiba
  module Tms
    module ObjectTypes
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable

      setting :id_field, default: :objecttypeid, reader: true
      setting :type_field, default: :objecttype, reader: true
      setting :used_in,
        default: [
          "Objects.#{id_field}"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable
    end
  end
end
