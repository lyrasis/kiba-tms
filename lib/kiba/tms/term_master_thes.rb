# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module TermMasterThes
      extend Dry::Configurable
      extend Tms::Mixins::AutoConfigurable
      module_function

      setting :delete_fields,
        default: %i[dateentered datemodified termclassid displaydescriptorid],
        reader: true
      setting :empty_fields, default: %i[], reader: true
    end
  end
end
