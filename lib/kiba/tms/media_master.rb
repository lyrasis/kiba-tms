# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module MediaMaster
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable

      setting :publishable_transform,
        default: Tms::Transforms::MediaMaster::SetPublishable,
        reader: true

      # So far, in all TMS migrations, the value of :displayrendid equals
      #   the value of :primaryrendid in this table. If true, this holds for
      #   current client. If false, there may be more work to be done in
      #   developing handling of the different renditions
      setting :display_is_primary, default: true, reader: true

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
