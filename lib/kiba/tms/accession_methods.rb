# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module AccessionMethods
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable

      setting :id_field, default: :accessionmethodid, reader: true
      setting :type_field, default: :accessionmethod, reader: true
      setting :used_in,
        default: [
          "ObjAccession.#{id_field}",
          "RegistrationSets.#{id_field}"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable
    end
  end
end
