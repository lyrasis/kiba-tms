# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module AssocParents
      extend Dry::Configurable

      # Fields beyond DeleteTmsFields general fields to delete
      setting :delete_fields, default: %i[complete mixed], reader: true
    end
  end
end
