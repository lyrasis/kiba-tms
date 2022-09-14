# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module TreatmentPriorities
      extend Dry::Configurable
      extend Tms::Mixins::MultiTableMergeable
      extend Tms::Mixins::AutoConfigurable
      extend Tms::Mixins::TypeLookupTable
      module_function

      setting :delete_fields, default: %i[], reader: true
      setting :empty_fields, default: %i[], reader: true
      
      setting :id_field, default: :priorityid, reader: true
      setting :type_field, default: :priority, reader: true
      setting :used_in,
        default: [
          "Conditions.treatmentpriorityid",
          "ConservationReports.treatmentpriorityid"
        ],
        reader: true
      setting :mappings, default: {}, reader: true
    end
  end
end
