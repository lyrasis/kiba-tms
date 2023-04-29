# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module EMailTypes
      extend Dry::Configurable
      module_function

      extend Tms::Mixins::Tableable

      setting :id_field, default: :emailtypeid, reader: true
      setting :type_field, default: :emailtype, reader: true
      setting :used_in,
        default: [
          "ConEMail.#{id_field}"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable
    end
  end
end
