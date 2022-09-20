# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module LoanObjXrefs
      extend Dry::Configurable
      module_function

      setting :delete_fields, default: [], reader: true
      setting :empty_fields, default: {}, reader: true
      extend Tms::Mixins::Tableable


      setting :merging_into_loans, default: true, reader: true
      setting :merging_into_objects, default: true, reader: true
      
      setting :conditions, reader: true do
        setting :record, default: :loan, reader: true
        setting :field, default: :loanconditions, reader: true
        setting :label, default: :objectnumber, reader: true
      end

    end
  end
end
