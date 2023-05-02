# frozen_string_literal: true

module Kiba
  module Tms
    module Packages
      extend Dry::Configurable

      module_function

      setting :delete_fields,
        default: %i[shortcut rbhistoryfolderid templaterecid displayrecid
                    bitmapname global locked packagepurposeid],
        reader: true
      extend Tms::Mixins::Tableable

      # TMS tables that map to CS authorities, and thus cannot be added to groups
      setting :omit_tables,
        default: %w[Constituents HistEvents ReferenceMaster],
        reader: true
    end
  end
end
