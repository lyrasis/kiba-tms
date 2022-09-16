# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module Classifications
      extend Dry::Configurable
      extend Tms::Mixins::Tableable
      extend Tms::Mixins::TypeLookupTable
      module_function

      setting :delete_fields, default: %i[], reader: true
      setting :empty_fields, default: {}, reader: true
      
      setting :id_field, default: :classificationid, reader: true
      setting :type_field, default: :classification, reader: true
      setting :used_in,
        default: [
          "ClassificationXrefs.#{id_field}",
          "Objects.#{id_field}"
        ],
        reader: true
      setting :mappings, default: {}, reader: true
    end
  end
end
