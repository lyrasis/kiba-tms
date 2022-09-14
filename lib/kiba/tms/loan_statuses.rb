# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module LoanStatuses
      extend Dry::Configurable
      extend Tms::Mixins::AutoConfigurable
      extend Tms::Mixins::TypeLookupTable
      module_function

      setting :delete_fields, default: %i[], reader: true
      setting :empty_fields, default: %i[], reader: true
      
      setting :id_field, default: :loanstatusid, reader: true
      setting :type_field, default: :loanstatus, reader: true
      setting :used_in,
        default: [
          "Loans.#{id_field}"
        ],
        reader: true
      setting :mappings, default: {}, reader: true
    end
  end
end
