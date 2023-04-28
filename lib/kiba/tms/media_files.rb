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

      # Client-specific transform(s) to clean up prepped data. Run at the end
      #   of :prep__media_files. Use to manually correct path/filenames that
      #   do not match uploaded files, as needed
      setting :prepped_data_cleaners,
        default: [],
        reader: true
      # Fields to combine into :description field
      setting :description_sources,
        default: %i[ms_description ms_publiccaption ms_mediaview],
        reader: true
      # Fields from MediaMaster to merge into MediaFiles
      setting :master_merge_fields,
        default: [],
        reader: true
      # Project-specific transform to create :mediafileuri value
      setting :mediafileuri_generator,
        default: Tms::Transforms::MediaFiles::UriGenerator,
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
      setting :bucket_name,
        default: nil,
        reader: true
      setting :media_handling_fields,
        default: %i[identificationnumber title publishto name mimetype length
                    externalurl measuredpart dimensionsummary dimension
                    measuredbypersonlocal measuredbyorganizationlocal
                    measurementmethod value measurementunit valuequalifier
                    valuedate measuredpartnote checksumvalue checksumtype
                    checksumdate contributorpersonlocal
                    contributororganizationlocal creatorpersonlocal
                    creatororganizationlocal language publisherpersonlocal
                    publisherorganizationlocal relation copyrightstatement type
                    coverage dategroup source subject rightsholderpersonlocal
                    rightsholderorganizationlocal description alttext
                    mediafileuri],
        reader: true

      def s3_url_base
        return "" unless bucket_name

        "https://#{bucket_name}.s3.us-west-2.amazonaws.com"
      end
    end
  end
end
