# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module MediaFiles
      extend Dry::Configurable
      module_function

      setting :delete_fields,
        default: %i[formatid pixelh pixelw colordepthid filesize
                    memorysize],
        reader: true
      extend Tms::Mixins::Tableable

      setting :master_merge_fields,
        default: [],
        reader: true
      setting :rendition_merge_fields,
        default: [],
        reader: true
    end
  end
end
