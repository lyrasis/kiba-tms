# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        # If preferred name field is blank and non-preferred name field is not,
        #   copy non-preferred name value to preferred name field
        class PrefFromNonPref
          def initialize
            @pref = Tms::Constituents.preferred_name_field
            @nonpref = Tms::Constituents.var_name_field
          end

          # @private
          def process(row)
            prefname = row[pref]
            return row unless prefname.blank?

            varname = row[nonpref]
            return row if varname.blank?

            row[pref] = varname
            row
          end

          private

          attr_reader :pref, :nonpref
        end
      end
    end
  end
end
