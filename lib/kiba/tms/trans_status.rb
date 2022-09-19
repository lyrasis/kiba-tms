# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    # For the clients whose data I'm working with when developing this, the TransStatus
    #   table is empty in their TMS database, but they see values in the application, and
    #   can provide a mapping that should be used to manually create a "supplied" table in
    #   their TMS source files directory.
    module TransStatus
      extend Dry::Configurable
      extend Tms::Mixins::Tableable
      extend Tms::Mixins::TypeLookupTable
      module_function

      setting :delete_fields, default: %i[], reader: true
      setting :empty_fields, default: {}, reader: true
      
      setting :id_field, default: :transstatusid, reader: true
      setting :type_field, default: :transstatus, reader: true
      setting :used_in,
        default: [
          "ObjLocations.#{id_field}",
          "ShipCrateHiers.#{id_field}"
        ],
        reader: true
      setting :mappings, default: {}, reader: true
    end
  end
end
