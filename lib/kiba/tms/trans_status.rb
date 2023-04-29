# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    # For the clients whose data I'm working with when developing this, the
    #   TransStatus table is empty in their TMS database, but they see values in
    #   the application, and can provide a mapping that should be used to
    #   manually create a "supplied" table in their TMS source files directory.
    module TransStatus
      extend Dry::Configurable
      module_function

      extend Tms::Mixins::Tableable

      setting :id_field, default: :transstatusid, reader: true
      setting :type_field, default: :transstatus, reader: true
      setting :used_in,
        default: [
          "ObjLocations.#{id_field}",
#          "ShipCrateHiers.#{id_field}"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable
      def default_mapping_treatment
        :self
      end
    end
  end
end
