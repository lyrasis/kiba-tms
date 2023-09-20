# frozen_string_literal: true

module Kiba
  module Tms
    module MediaFiles
      extend Dry::Configurable

      module_function

      # IMPLEMENTATION NOTE:
      # To generate the file list from the S3 bucket and put it in the
      #   expected place, run the following command:
      #
      # aws s3 ls s3://bucketname --recursive --profile cs-media > ~/data/project/mig/supplied/aws_ls.csv

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[formatid pixelh pixelw colordepthid],
        reader: true
      extend Tms::Mixins::Tableable

      # MediaXrefs targettables that we cannot relate to MediaHandling
      #   procedures in CS
      setting :unmigratable_targets,
        default: ["Constituents", "ReferenceMaster"],
        reader: true

      # Whether to ingest Media Handling procedures that do not have an
      #   associated file
      setting :migrate_fileless,
        default: false,
        reader: true

      # Whether to ingest files that are related only to TMS targettables that
      #   are mapped to authority term records in CS
      setting :migrate_unmigratable,
        default: false,
        reader: true

      # Whether files not related to any table via MediaXrefs (i.e. targettable
      #   field is blank) will be migrated
      setting :migrate_unreferenced,
        default: false,
        reader: true

      # Fields to combine into :description field
      setting :description_sources,
        default: %i[ms_description ms_publiccaption ms_mediaview],
        reader: true

      # Fields from MediaMaster to merge into MediaFiles. Merged in field names
      #   are prefixed with "ms_"
      setting :master_merge_fields,
        default: [],
        reader: true

      # Fields from MediaRenditions to merge into MediaFiles. Merged in field
      #   names are prefixed with "mr_"
      setting :rendition_merge_fields,
        default: [],
        reader: true

      # Client-specific transform(s) to clean up prepped data. Run at the end
      #   of :prep__media_files. Use to manually correct path/filenames that
      #   do not match uploaded files, as needed
      setting :prepped_data_cleaners,
        default: [],
        reader: true

      # Project-specific transforms to be run at the beginning of
      #   MediaFiles::Shaped job
      setting :post_merge_transforms, default: [], reader: true

      # Project-specific transform to create :mediafileuri value
      setting :mediafileuri_generator,
        default: Tms::Transforms::MediaFiles::UriGenerator,
        reader: true

      # Whether media files have been uploaded to S3 bucket for ingest
      setting :files_uploaded,
        default: false,
        reader: true

      # Name of AWS S3 bucket containing ingestable media files
      setting :bucket_name,
        default: nil,
        reader: true

      # Directory created at bucket base, into which client uploaded ALL
      #  files. Only needed if client created such a directory.
      setting :bucket_base_dir,
        default: nil,
        reader: true

      # Prefixes to remove from paths stored in TMS, for matching against
      #  S3 paths. Typically these will indicate the local filesystems where
      #  TMS data was stored prior to being uploaded to S3
      setting :tms_path_bases,
        default: [],
        reader: true

      # All ingestable data fields for CS media ingest
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

      # Prefix added to S3 bucket file path to create a URI from which the file
      #   can be accessed/ingested by the CS instance
      def s3_url_base
        return "" unless bucket_name

        "https://#{bucket_name}.s3.us-west-2.amazonaws.com"
      end
    end
  end
end
