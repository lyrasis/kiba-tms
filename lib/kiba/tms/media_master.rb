# frozen_string_literal: true

module Kiba
  module Tms
    module MediaMaster
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable

      # @return [Proc] Used in :publishable_transform. The proc should take a
      #   row and return a Boolean or nil value regarding whether row's record
      #   is publishable
      setting :publishable_logic,
        default: ->(row) do
          true if row[:publicaccess] == "1" && row[:approvedforweb] == "1"
        end,
        reader: true

      setting :publishable_transform,
        default: Tms::Transforms::MediaMaster::SetPublishable,
        reader: true

      # So far, in all TMS migrations, the value of :displayrendid equals
      #   the value of :primaryrendid in this table. If true, this holds for
      #   current client. If false, there may be more work to be done in
      #   developing handling of the different renditions
      setting :display_is_primary, default: true, reader: true

      # Defines how auto-generated config settings are populated
      setting :configurable,
        default: {
          display_is_primary: proc {
            Tms::Services::MediaMaster::DisplayIsPrimaryDeriver.call
          }
        },
        reader: true
    end
  end
end
