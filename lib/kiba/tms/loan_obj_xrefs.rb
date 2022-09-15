# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module LoanObjXrefs
      module_function
      
      extend Dry::Configurable

      def used?
        true
      end
      # whether or not table is used
      setting :used, default: ->{ Tms::Table::List.include?('LoanObjXrefs') }, reader: true
      setting :delete_fields, default: %i[], reader: true
      setting :empty_fields, default: %i[], reader: true

      setting :merging_into_loans, default: true, reader: true
      setting :merging_into_objects, default: true, reader: true
      
      setting :conditions, reader: true do
        setting :record, default: :loan, reader: true
        setting :field, default: :loanconditions, reader: true
        setting :label, default: :objectnumber, reader: true
      end
      
      def omitted_fields
        ( delete_fields + empty_fields ).uniq
      end
    end
  end
end
