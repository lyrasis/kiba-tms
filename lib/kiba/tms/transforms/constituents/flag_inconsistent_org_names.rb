# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        # Adds :check_org_names field when:
        # - :constituenttype = Organization
        # - :institution value is present (indicating it is not equal to preferred or non-preferred name type)
        # - :preferred name field value and var name field (not blanked) are different
        class FlagInconsistentOrgNames
          def initialize
            @type = :constituenttype
            @inst = :institution
            @pref = Tms::Constituents.preferred_name_field
            @alt = Tms::Constituents.var_name_field
            @target = :inconsistent_org_names
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(fields: [pref, alt])
          end

          # @private
          def process(row)
            row[target] = nil
            type_val = row[type]
            return row if type_val.blank?
            return row unless type_val == "Organization"

            inst_val = row[inst]
            unless inst_val.blank?
              row[target] = "y"
              return row
            end

            vals = getter.call(row).values.uniq
            return row if vals.length == 1

            row[target] = "y"
            row
          end

          private

          attr_reader :type, :inst, :pref, :alt, :target, :getter
        end
      end
    end
  end
end
