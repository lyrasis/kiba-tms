# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module LoanObjStatuses
      module_function
      
      extend Dry::Configurable
      # whether or not table is used
      setting :used, default: ->{ Tms::Tables::List.include?('LoanObjStatuses') }, reader: true
      # Fields beyond DeleteTmsFields general fields to delete
      setting :delete_fields, default: %i[system onview], reader: true
    end
  end
end
