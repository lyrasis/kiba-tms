# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        class FlagPersonNamesLackingNameDetails
          include Kiba::Extend::Transforms::Helpers

          def initialize
            @type = :constituenttype
            @target = :missing_last_name
          end

          # @private
          def process(row)
            row[target] = nil
            type_val = row.fetch(type, nil)
            return row if type_val.blank?
            return row unless type_val == "Person"

            val = row.fetch(:lastname, nil)
            return row unless val.blank?

            row[target] = "y"
            row
          end

          private

          attr_reader :type, :target
        end
      end
    end
  end
end
