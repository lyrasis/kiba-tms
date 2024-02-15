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
      #   true, triggers retention or original :locationstring value in
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
