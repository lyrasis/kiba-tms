# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ObjCompTypes
      extend Dry::Configurable
      # map values in TMS table to CS object hierarchy relation types
      setting :type_mapping, default: {}, reader: true
    end
  end
end
