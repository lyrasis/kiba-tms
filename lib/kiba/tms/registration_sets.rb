# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module RegistrationSets
      extend Dry::Configurable
      extend Tms::Mixins::Omittable
      # whether or not table is used
      setting :used, default: ->{ Tms::Table::List.include?('RegistrationSets') }, reader: true
      # Fields beyond DeleteTmsFields general fields to delete
      setting :delete_fields, default: %i[], reader: true
      setting :empty_fields, default: %i[], reader: true
    end
  end
end
