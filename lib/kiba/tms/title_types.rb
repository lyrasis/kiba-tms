# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module TitleTypes
      module_function
      extend Dry::Configurable

      setting :type_mapping, default: {}, reader: true
    end
  end
end
