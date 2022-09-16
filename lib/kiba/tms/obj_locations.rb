# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ObjLocations
      extend Dry::Configurable
      module_function

      # The first three rows are fields all marked as not in use in the TMS data dictionary
      setting :delete_fields,
        default: %i[],
        reader: true
      setting :empty_fields,
        default: {
          dateout: [nil, '', '9999-12-31 00:00:00.000'],
          tempticklerdate: [nil, '', '1900-01-01 00:00:00.000']
        },
        reader: true
      extend Tms::Mixins::Tableable
    end
  end
end
