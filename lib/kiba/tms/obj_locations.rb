# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ObjLocations
      extend Dry::Configurable
      module_function

      # The first three rows are fields all marked as not in use in the TMS data dictionary
      setting :delete_fields,
        default: %i[currencyamount currencyrate localamount
                    accessionminutes1 accessionminutes2 budget capitalprogram
                    currencyid originalentityid currententityid],
        reader: true
      setting :empty_fields, default: {}, reader: true
      extend Tms::Mixins::Tableable
    end
  end
end
