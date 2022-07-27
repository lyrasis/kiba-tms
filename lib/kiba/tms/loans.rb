# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module Loans
      extend Dry::Configurable
      # whether or not table is used
      setting :used, default: ->{ Tms.excluded_tables.none?('Loans') }, reader: true
      # Fields beyond DeleteTmsFields general fields to delete
      setting :delete_fields, default: %i[], reader: true
    end
  end
end
