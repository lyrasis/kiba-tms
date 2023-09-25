# frozen_string_literal: true

module Kiba
  module Tms
    module Dimensions
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[displayed dimensionid],
        reader: true
      extend Tms::Mixins::Tableable

      # If primary unit is inches, TMS secondary unit will be cm. If
      #   client wants to keep both the inch and cm values ***in a
      #   structured manner*** for *EVERY* dimension recorded, this
      #   should be set to true. In the real world, it is unlikely
      #   that any users will consistently enter the metric AND
      #   imperial values for every recorded dimension when entering
      #   data manually. For this reason, we default to false, and
      #   migrate only the values manually recorded in TMS, not the
      #   derived secondary unit values.
      setting :migrate_secondary_unit_vals,
        default: false,
        reader: true
    end
  end
end
