# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        # Adds :check_org_names field when:
        # - :constituenttype = Organization
        # - :institution value is present (indicating it is not equal to preferred or non-preferred name type)
        class FlagInconsistentOrgNames
          include Kiba::Extend::Transforms::Helpers
          
          def initialize
            @type = :constituenttype
            @inst = :institution
            @pref = Tms.constituents.preferred_name_field
            @alt = Tms.constituents.var_name_field
            @target = :inconsistent_org_names
          end

          # @private
          def process(row)
            row[target] = nil
            type_val = row.fetch(type, nil)
            return row if type_val.blank?
            return row unless type_val == 'Organization'

            inst_val = row.fetch(inst, nil)
            unless inst_val.blank?
              row[target] = 'y'
              return row
            end

            vals = field_values(row: row, fields: [pref, alt]).values.uniq
            return row if vals.length == 1

            row[target] = 'y'
            row
          end

          private

          attr_reader :type, :inst, :pref, :alt, :target
        end
      end
    end
  end
end
