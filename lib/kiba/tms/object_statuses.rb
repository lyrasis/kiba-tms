# frozen_string_literal: true

module Kiba
  module Tms
    module ObjectStatuses
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
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

      def default_mapping_treatment
        :downcase
      end
    end
  end
end
