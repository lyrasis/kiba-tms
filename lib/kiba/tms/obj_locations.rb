# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ObjLocations
      extend Dry::Configurable
      module_function

      setting :empty_fields,
        default: {
          dateout: [nil, '', '9999-12-31 00:00:00.000'],
          tempticklerdate: [nil, '', '1900-01-01 00:00:00.000']
        },
        reader: true
      extend Tms::Mixins::Tableable

      setting :name_fields,
        default: %i[handler requestedby approver],
        reader: true
      extend Tms::Mixins::UncontrolledNameCompileable

      # Which fields in obj_locations need to be concatenated with the location
      #   value to create additional location values (and thus need a unique id
      #   added to look them up)
      setting :fulllocid_fields,
        default: %i[locationid loclevel searchcontainer temptext shipmentid
                    crateid sublevel],
        reader: true
      setting :temptext_mapping_done,
        default: false,
        reader: true
    end
  end
end
