# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      # Removes empty money field values from the end of fields
      class DeleteEmptyMoney
        def initialize(fields:)
          @fields = fields
          @value = ".0000"
        end

        def process(row)
          fields.each { |field| delete_value(row, field) }
          row
        end

        private

        attr_reader :fields, :value

        def delete_value(row, field)
          val = row[field]
          return if val.blank?
          return unless val == value

          row[field] = nil
        end
      end
    end
  end
end
