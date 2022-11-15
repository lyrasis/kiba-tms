# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module MediaFiles
      extend Dry::Configurable
      module_function

      setting :delete_fields,
        default: %i[formatid pixelh pixelw colordepthid],
        reader: true
      extend Tms::Mixins::Tableable

      setting :master_merge_fields,
        default: [],
        reader: true
      setting :migrate_fileless,
        default: false,
        reader: true
      # Whether to ingest files that are related only to authority-destined
      #   records via MediaXrefs
      setting :migrate_unmigratable,
        default: false,
        reader: true
      # Whether files not related to any table via MediaXrefs (i.e. targettable
      #   field is blank) will be migrated
      setting :migrate_unreferenced,
        default: false,
        reader: true
      setting :rendition_merge_fields,
        default: [],
        reader: true
      # MediaXrefs targettables that we cannot relate to MediaHandling
      #   procedures in CS
      setting :unmigratable_targets,
        default: ['Constituents', 'ReferenceMaster'],
        reader: true
    end
  end
end
