# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      # Removes empty timestamps from the end of date fields
      class DeleteTimestamps

        def initialize(fields:)
          @fields = [fields].flatten
          @pattern = Regexp.new(' \d{2}:.*$')
        end

        def process(row)
          fields.each{ |field| delete_timestamp(row, field) }
          row
        end

        private

        attr_reader :fields, :pattern

        def delete_timestamp(row, field)
          val = row[field]
          return if val.blank?
          return unless val.match?(pattern)

          row[field] = val.sub(pattern, "")
        end
      end
    end
  end
end
