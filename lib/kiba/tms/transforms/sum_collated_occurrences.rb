# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      # Splits on delim, converts to numbers, replaces with sum of numbers
      #
      # If any value has anything other than digits, returns original value and
      #   put a warning.
      class SumCollatedOccurrences
        include Kiba::Extend::Transforms::SingleWarnable

        # @param field [Symbol]
        # @param delim [String]
        def initialize(field:, delim: Tms.delim)
          @field = field
          @delim = delim
          setup_single_warning
        end

        def process(row)
          fieldval = row[field]
          return row if fieldval.blank?

          vals = fieldval.split(delim)

          if valid?(vals)
            row[field] = vals.map(&:to_i).sum
          else
            add_single_warning(
              "#{self.class.name}: Non-numeric value(s) in #{field}"
            )
          end

          row
        end

        private

        attr_reader :field, :delim

        def valid?(vals)
          vals.map { |val| val.match?(/^\d+$/) }.all?
        end
      end
    end
  end
end
