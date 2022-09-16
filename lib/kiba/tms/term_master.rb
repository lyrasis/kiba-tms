# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module TermMaster
      extend Dry::Configurable
      extend Tms::Mixins::Tableable
      module_function

      setting :delete_fields,
        default: %i[dateentered datemodified termclassid displaydescriptorid],
        reader: true
      setting :empty_fields, default: {}, reader: true
    end
  end
end
