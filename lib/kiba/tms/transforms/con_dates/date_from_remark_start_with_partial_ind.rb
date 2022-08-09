# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConDates
        # If :date is blank and :remarks begins with a partial date indicator,
        #   move value of :remarks to :date
        class DateFromRemarkStartWithPartialInd
          def initialize
            @indicators = Tms::Constituents.dates.partial_date_indicators
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

          attr_reader :indicators

          def eligible?(remark)
            indicators.any?{ |ind| remark.start_with?(ind) }
          end
        end
      end
    end
  end
end
