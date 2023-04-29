# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module LoanStatuses
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable

      setting :id_field, default: :loanstatusid, reader: true
      setting :type_field, default: :loanstatus, reader: true
      setting :used_in,
        default: [
          "Loans.#{id_field}"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable
    end
  end
end
