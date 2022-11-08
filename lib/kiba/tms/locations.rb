# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module Locations
      extend Dry::Configurable
      module_function

      extend Tms::Mixins::Tableable

      # which authority types to process records and hierarchies for
      #   (organizations used as locations are handled a bit separately
      setting :authorities, default: %i[local offsite], reader: true
      setting :brief_address_mappings, default: {}, reader: true
      setting :cleanup_iteration, default: 0, reader: true
      # Which fields in obj_locations need to be concatenated with the location
      #   value to create additional location values (and thus need a unique id
      #   added to look them up)
      setting :fulllocid_fields,
        default: %i[locationid loclevel searchcontainer temptext shipmentid
                    crateid sublevel],
        reader: true
      # Whether client wants the migration to include construction of a location
      #   hierarchy
      setting :hierarchy, default: true, reader: true
      setting :hierarchy_delim, default: ' > ', reader: true
      setting :initial_data_cleaner, default: nil, reader: true
      # base fields from Locations table to concatenate into location name
      setting :loc_fields,
        default: %i[brief_address site room unittype unitnumber unitposition],
        reader: true
      setting :multi_source_normalizer,
        default: Kiba::Extend::Utils::MultiSourceNormalizer.new,
        reader: true
    end
  end
end
