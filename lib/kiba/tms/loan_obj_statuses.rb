# frozen_string_literal: true

module Kiba
  module Tms
    module LoanObjStatuses
      extend Dry::Configurable

      module_function

      extend Tms::Mixins::Tableable

      setting :id_field, default: :loanobjectstatusid, reader: true
      setting :type_field, default: :loanobjectstatus, reader: true
      setting :used_in,
        default: [
          "LoanObjXrefs.#{id_field}"
        ],
        reader: true
      extend Tms::Mixins::TypeLookupTable
    end
  end
end
