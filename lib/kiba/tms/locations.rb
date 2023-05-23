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

      # which authority types to process records and hierarchies for
      #   (organizations used as locations are handled a bit separately
      setting :authorities, default: %i[local offsite], reader: true
      setting :brief_address_mappings, default: {}, reader: true
      setting :cleanup_done, default: false, reader: true,
        constructor: proc { !returned_files.empty? }
      # Whether client wants the migration to include construction of a location
      #   hierarchy
      setting :hierarchy, default: true, reader: true
      setting :hierarchy_delim, default: " > ", reader: true
      # special/client customized data cleanup of Locations table prior to any
      #   other transforms
      setting :initial_data_cleaner, default: nil, reader: true
      # base fields from Locations table to concatenate into location name
      setting :loc_fields,
        default: %i[brief_address site room unittype unitnumber unitposition],
        reader: true
      setting :populate_storage_loc_type,
        default: false,
        reader: true
      # optional custom transform to be run at end of Locations::Compiled
      setting :post_compile_xform,
        default: nil,
        reader: true
      # Filenames of location review/cleanup worksheets provided to the client.
      #   Most recent first. Assumes files are in the `to_client` subdirectory
      #   of the migration base directory
      setting :provided_worksheets,
        reader: true,
        constructor: proc { |value|
          value.map do |filename|
            File.join(Kiba::Tms.datadir, "to_client", filename)
          end
        }
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
      setting :multi_source_normalizer,
        default: Kiba::Extend::Utils::MultiSourceNormalizer.new,
        reader: true

      def authority_vocab_mapping
        if authorities.any?(:offsite)
          {"0" => "Local", "1" => "Offsite"}
        else
          {"0" => "Local", "1" => "Local"}
        end
      end

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
