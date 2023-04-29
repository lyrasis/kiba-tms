# frozen_string_literal: true

require "chronic"

module Kiba
  module Tms
    module Mixins
      module DateSortable
        def parsed_sort_date(str)
          parsed = Chronic.parse(str)
        rescue
          warn("Problem parsing date: #{str}")
          Date.new(1000, 1, 1)
        else
          return Date.new(1000, 1, 1) unless parsed

          parsed
        end

        def sortable_date_from_row(row, field)
          datevalue = row[field]
          return Date.new(1000, 1, 1) if datevalue.blank?

          parsed_sort_date(datevalue)
        end
      end
    end
  end
end
