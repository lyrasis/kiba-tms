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

      # Fields to combine into :description field
      setting :description_sources,
        default: %i[ms_description ms_publiccaption ms_mediaview],
        reader: true
      # Fields from MediaMaster to merge into MediaFiles
      setting :master_merge_fields,
        default: [],
        reader: true
      # Project-specific transform to create :mediafileuri value
      setting :mediafileuri_generator, default: nil, reader: true
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
      # Project-specific transforms to be run at the beginning of
      #   MediaFiles::Shaped job
      setting :post_merge_transforms, default: [], reader: true
      # Fields from MediaRenditions to merge into MediaFiles
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
