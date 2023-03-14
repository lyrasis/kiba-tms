# frozen_string_literal: true

module Kiba
  module Tms
    module Packages
      extend Dry::Configurable
      module_function

      setting :delete_fields,
        default: %i[shortcut rbhistoryfolderid templaterecid displayrecid],
        reader: true
      extend Tms::Mixins::Tableable
    end
  end
end
