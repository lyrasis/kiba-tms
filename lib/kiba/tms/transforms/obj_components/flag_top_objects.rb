# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ObjComponents
        class FlagTopObjects
          include Kiba::Extend::Transforms::Helpers

          def initialize
            @fields = %i[parentobjectnumber componentnumber]
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(fields: fields)
            @target = :is_top_object
          end

          def process(row)
            row[target] = nil

            nums = getter.call(row).values.uniq.length
            return row if nums > 1

            row[target] = "y"
            row
          end

          private

          attr_reader :fields, :getter, :target
        end
      end
    end
  end
end
