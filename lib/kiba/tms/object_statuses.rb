# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module ObjectStatuses
      extend Dry::Configurable

      module_function

      setting :delete_fields, default: %i[inpermanentjurisdiction system],
        reader: true
      extend Tms::Mixins::Tableable

      setting :id_field, default: :objectstatusid, reader: true
      setting :type_field, default: :objectstatus, reader: true
      setting :used_in,
        default: [
          "Objects.#{id_field}",
          "RegistrationSets.#{id_field}"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable
    end
  end
end
