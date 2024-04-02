# frozen_string_literal: true

module Kiba
  module Tms
    module Locations
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[publicaccess unitmaxlevels bitmapname xcoord ycoord],
        reader: true,
        constructor: ->(value) {
          if Tms::ConservationEntities.used?
            value
          else
            value << :conservationentityid
          end
        }
      extend Tms::Mixins::Tableable

      # @return [Array<Symbol>] which authority types to process
      #   records and hierarchies for (organizations used as locations
      #   are handled a bit separately
      setting :authorities, default: %i[local offsite], reader: true

      # @return [Boolean] whether to retain inactive location terms in
      #   migration. If this is false, there may be effects in loading/migrating
      #   LMIs using inactive locations as the current location, since the
      #   needed location term will not exist, and LMIs require a current
      #   location.
      setting :migrate_inactive, default: true, reader: true

      # @return [String] inserted in target field if record is inactive. Has no
      #   effect if `:inactive_treatment` = `:none`. If `:inactive_treatment` =
      #   `:status`, you will need to add the value to the optionlist
      #   populating termStatus.
      setting :inactive_label,
        default: "DO NOT USE - INACTIVE",
        reader: true

      # @return [:status, :type, :none] how to represent inactive term
      #   status in CollectionSpace term records. `:status` will set
      #   the termStatus value to the string in `:inactive_label`. You
      #   will need add the value to the optionlist config. `:type`
      #   will set the locationType field to the string in
      #   `:inactive_label`. This will overwrite any other locationType
      #   value that may be derived for the location term. This
      #   treatment is the default because the locationType value of a
      #   term can be viewed when using the term in an LMI or other
      #   record. `:none` will drop the field indicating whether a
      #   location is active or not from the migration.
      setting :inactive_treatment, default: :type, reader: true

      # @return [:termqualifier, :termsourcenote, :securitynote, :accessnote,
      #   :conditionnote] CS Location term field into which TMS
      #   Locations.description data should be mapped. Do not use
      #   :termqualifier or :termsourcenote if those fields are already being
      #   used in your migration
      setting :description_target, default: :termqualifier, reader: true

      # @return [Boolean] whether to remove description values that occur
      #   within termdisplayname or termname values
      setting :deduplicate_description, default: true, reader: true

      # @return [Hash] mapping of TMS Locations.External field value to
      #  authority vocabulary
      def authority_vocab_mapping
        if authorities.any?(:offsite)
          {"0" => "Local", "1" => "Offsite"}
        else
          {"0" => "Local", "1" => "Local"}
        end
      end

      # @return [Boolean] whether terms have been abbreviated in cleanup. If
      #   true, triggers retention of original :locationstring value in
      #   CollectionSpace :name field
      setting :terms_abbreviated, default: false, reader: true

      # @return [Hash] mapping of literal :briefaddress values merged into
      #   prep__locations via TMS Locations.addressid field to values for use
      #   in the migration. Usually these are briefer forms of the value
      setting :brief_address_mappings, default: {}, reader: true

      # Whether client wants the migration to include construction of a location
      # hierarchy
      #
      # NOTE: In order to ensure unique storage location terms that make sense
      # without having to look at the hierarchy, each location term expresses
      # its hierarchy. This setting controls whether we will be creating the
      # hierarchical relationships in CollectionSpace
      setting :hierarchy, default: true, reader: true

      # In order to ensure unique storage location terms that make
      # sense without having to look at the hierarchy, each location
      # term expresses its hierarchy. This setting controls the order
      # of the hierarchical segments in each term.
      #
      # Options:
      # - :broad_to_narrow - the default
      # - :narrow_to_broad - Use if client has long location values
      # that can't be shortened, so you can see the most
      # specific/relevant part in search results lists or field
      # displays, even if the full term is quite long.
      setting :term_hierarchy_direction,
        default: :broad_to_narrow,
        reader: true

      # String used between the hierarchical segments in term display name
      setting :hierarchy_delim,
        default: " > ",
        reader: true,
        constructor: ->(default) do
          return default if term_hierarchy_direction == :broad_to_narrow

          " < " if term_hierarchy_direction == :narrow_to_broad
        end

      # Fields from TMS Locations table to concatenate into location term. E.g.
      # the levels of the hierarchy, indicated broad-to-narrow in this setting
      setting :loc_fields,
        default: %i[brief_address site room unittype unitnumber unitposition],
        reader: true

      # Whether the CollectionSpace locationType field should be auto-populated,
      # where possible, from data in the TMS Locations table
      setting :populate_storage_loc_type,
        default: false,
        reader: true

      # special/client customized data cleanup of Locations table prior to any
      #   other transforms
      setting :initial_data_cleaner, default: nil, reader: true

      # optional custom transform to be run at end of Locations::Compiled
      setting :post_compile_xform,
        default: nil,
        reader: true

      # Filenames of location review/cleanup worksheets provided to the client.
      #   Most recent first. Assumes files are in the `to_client` subdirectory
      #   of the migration base directory
      setting :provided_worksheets,
        default: [],
        reader: true,
        constructor: ->(value) do
          value.map do |filename|
            File.join(Kiba::Tms.datadir, "to_client", filename)
          end
        end

      # List returned worksheets, most recent first. Assumes they are in the
      #   client project directory/supplied subdir
      setting :returned_files,
        default: [],
        reader: true,
        constructor: proc { |value|
          value.map do |filename|
            File.join(Kiba::Tms.datadir, "supplied", filename)
          end
        }

      # @return [Boolean]
      setting :cleanup_done, default: false, reader: true,
        constructor: proc { !returned_files.empty? }

      def provided_worksheet_jobs
        provided_worksheets.map.with_index do |filename, idx|
          "locs__worksheet_provided_#{idx}".to_sym
        end
      end

      def returned_file_jobs
        returned_files.map.with_index do |filename, idx|
          "locs__worksheet_completed_#{idx}".to_sym
        end
      end

      def worksheet_columns
        base = %i[usage_ct]
        base << :to_review if cleanup_done
        base << %i[location_name correct_location_name
          storage_location_authority correct_authority
          address correct_address
          term_source fulllocid origlocname]
        base.flatten
      end
    end
  end
end
