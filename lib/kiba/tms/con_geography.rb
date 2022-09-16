# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ConGeography
      extend Dry::Configurable
      module_function

      # The first three rows are fields all marked as not in use in the TMS data dictionary
      setting :delete_fields,
        default: %i[keyfieldssearchvalue primarydisplay],
        reader: true
      setting :empty_fields, default: {}, reader: true
      extend Tms::Mixins::Tableable
    end
  end
end
