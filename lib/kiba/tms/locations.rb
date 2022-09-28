# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module Locations
      extend Dry::Configurable
      module_function

      extend Tms::Mixins::Tableable

      setting :cleanup_iteration, default: 0, reader: true
      # Whether client wants the migration to include construction of a location
      #   hierarchy
      setting :hierarchy, default: true, reader: true
      setting :hierarchy_delim, default: ' > ', reader: true
      # Which fields in obj_locations need to be concatenated with the location
      #   value to create additional location values (and thus need a unique id
      #   added to look them up)
      setting :fulllocid_fields,
        default: %i[locationid loclevel searchcontainer temptext shipmentid
                    crateid sublevel],
        reader: true
      # which authority types to process records and hierarchies for
      #   (organizations used as locations are handled a bit separately
      setting :authorities, default: %i[local offsite], reader: true
      setting :multi_source_normalizer,
        default: Kiba::Extend::Utils::MultiSourceNormalizer.new,
        reader: true
    end
  end
end
