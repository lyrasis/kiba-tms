# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConDates
        # If :date is blank and :remarks begins with an abbreviated textual English month name,
        #   move value of :remarks to :date
        class DateFromRemarkStartWithAbbvMonth
          def initialize
            @months = Date::ABBR_MONTHNAMES.compact.map(&:downcase)
          end

          # @private
          def process(row)
            date = row[:date]
            return row unless date.blank?

            remark = row[:remarks]
            return row if remark.blank?
            return row unless eligible?(remark.downcase)

            row[:date] = remark
            row[:remarks] = nil
            row
          end
          
          private

          attr_reader :months

          def eligible?(remark)
            months.any?{ |month| remark.start_with?(month) }
          end
        end
      end
    end
  end
end
