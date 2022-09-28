# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module LoanObjXrefs
      extend Dry::Configurable
      module_function

      extend Tms::Mixins::Tableable

      setting :merging_into_loans, default: true, reader: true
      setting :merging_into_objects, default: true, reader: true

      # @return [:loan, :object] target record to merge conditions data into
      setting :conditions_record, default: :loan, reader: true
      # @return [:conditions, :note] field of target record to merge conditions
      #   data into
      setting :conditions_field, default: :conditions, reader: true
      # @return [:objectnumber, :loannumber] value to prepend to conditions field
      #   value
      setting :conditions_label, default: :objectnumber, reader: true
    end
  end
end
