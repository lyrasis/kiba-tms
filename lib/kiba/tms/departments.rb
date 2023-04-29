# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module Departments
      extend Dry::Configurable
      module_function

      setting :delete_fields,
        default: %i[mnemonic inputid numrandomobjs defaultformid],
        reader: true
      extend Tms::Mixins::Tableable

      setting :id_field, default: :departmentid, reader: true
      setting :type_field, default: :department, reader: true
      setting :used_in,
        default: [
          "ConservationReports.#{id_field}",
          "HistEvents.#{id_field}",
          "Loans.#{id_field}",
          "MediaMaster.#{id_field}",
          "Objects.#{id_field}",
          "Projects.#{id_field}",
          "ConXrefDetails.#{id_field}",
          "ObjPrefixes.#{id_field}"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable

      def default_mapping_treatment
        :self
      end
    end
  end
end
