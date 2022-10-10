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
    end
  end
end
