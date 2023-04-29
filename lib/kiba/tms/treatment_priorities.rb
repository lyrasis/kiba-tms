# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module TreatmentPriorities
      extend Dry::Configurable
      module_function

      extend Tms::Mixins::Tableable
      extend Tms::Mixins::MultiTableMergeable

      setting :id_field, default: :priorityid, reader: true
      setting :type_field, default: :priority, reader: true
      setting :used_in,
        default: [
          "Conditions.treatmentpriorityid",
          "ConservationReports.treatmentpriorityid"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable
    end
  end
end
