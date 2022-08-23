# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module LoanObjXrefs
      module_function
      
      extend Dry::Configurable
      # whether or not table is used
      setting :used, default: ->{ Tms::Table::List.include?('LoanObjXrefs') }, reader: true
      setting :delete_fields, default: %i[], reader: true
      setting :empty_fields, default: %i[], reader: true

      def omitted_fields
        ( delete_fields + empty_fields ).uniq
      end
    end
  end
end
