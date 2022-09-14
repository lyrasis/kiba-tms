# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module LoanObjStatuses
      extend Dry::Configurable
      extend Tms::Mixins::AutoConfigurable
      module_function

      setting :delete_fields, default: %i[], reader: true
      setting :empty_fields, default: %i[], reader: true
      
      setting :type_lookup, default: true, reader: true
      setting :id_field, default: :loanobjectstatusid, reader: true
      setting :type_field, default: :loanobjectstatus, reader: true
      setting :used_in,
        default: [
          "LoanObjXrefs.#{id_field}"
        ],
        reader: true
      setting :mappings, default: {}, reader: true
    end
  end
end
