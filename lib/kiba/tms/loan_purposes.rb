# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module LoanPurposes
      extend Dry::Configurable
      extend Tms::Omittable
      module_function

      # whether or not table is used
      setting :used, default: ->{ Tms::Table::List.include?('LoanPurposes') }, reader: true
      # Fields beyond DeleteTmsFields general fields to delete
      setting :delete_fields, default: %i[], reader: true
      setting :empty_fields, default: %i[], reader: true
      setting :mappings, default: {}, reader: true
      setting :unused_values, default: [], reader: true
    end
  end
end
