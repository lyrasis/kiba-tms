# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ObjComponents
        class FlagTopObjects
          include Kiba::Extend::Transforms::Helpers

          def initialize
            @target = :is_top_object
          end

          def process(row)
            row[target] = nil

            nums = field_values(row: row, fields: %i[objectnumber componentnumber]).values.uniq.length
            return row if nums > 1

            row[target] = 'y'
            row
          end

          private

          attr_reader :target
        end
      end
    end
  end
end
