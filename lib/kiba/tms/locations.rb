# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module Locations
      extend Dry::Configurable
      module_function

      setting :delete_fields,
        default: %i[publicaccess unitmaxlevels bitmapname xcoord ycoord],
        reader: true,
        constructor: ->(value){
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
      setting :cleanup_done, default: false, reader: true
      # Whether client wants the migration to include construction of a location
      #   hierarchy
      setting :hierarchy, default: true, reader: true
      setting :hierarchy_delim, default: ' > ', reader: true
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
      setting :multi_source_normalizer,
        default: Kiba::Extend::Utils::MultiSourceNormalizer.new,
        reader: true

      def authority_vocab_mapping
        if authorities.any?(:offsite)
          {'0'=>'Local', '1'=>'Offsite'}
        else
          {'0'=>'Local', '1'=>'Local'}
        end
      end
    end
  end
end
