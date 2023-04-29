# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConDates
        # Mix-in module with methods for adding warnings to indicated :target field
        #
        # ## Implementation
        #
        # Classes mixing in this module should have the following reader attributes:
        #
        # - `warning` - String - warning message
        # - `target` - Symbol - the target field for warnings
        module Warnable
          def add_warning(row, appended = nil)
            warns = warnings(row) << (appended ? "#{warning}#{appended}" : warning)
            row[target] = warns.join("; ")
          end

          def warnings(row)
            val = row[target]
            return [] if val.blank?

            val.split("; ")
          end
        end
      end
    end
  end
end
