# frozen_string_literal: true

module Kiba
  module Tms
    module LocPurposes
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable

      setting :id_field, default: :locpurposeid, reader: true
      setting :type_field, default: :locpurpose, reader: true
      setting :used_in,
        default: [
          "ObjLocations.#{id_field}"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable
    end
  end
end
