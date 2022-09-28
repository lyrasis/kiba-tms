# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module DispositionMethods
      extend Dry::Configurable
      module_function

      extend Tms::Mixins::Tableable

      setting :id_field, default: :dispmethodid, reader: true
      setting :type_field, default: :dispositionmethod, reader: true
      setting :used_in,
        default: [
          "ObjDeaccession.dispositionmethod"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable
    end
  end
end
