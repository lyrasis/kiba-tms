# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConDates
        # Not all rows have structured date data that was processed via DateFromParts.
        # This moves any `remarks` values beginning with 4 digits to the `date` field if the
        #   :date field is blank
        class DateFromRemarkStartingWithYr
          def initialize
            @target = :date
            @remark_start = Regexp.new(Tms::Constituents.dates.yr_remark_start)
          end

          # @private
          def process(row)
            val = row[target]
            return row unless val.blank?

            remark = row[:remarks]
            return row if remark.blank?
            return row unless remark.match?(remark_start)

            row[:date] = remark
            row[:remarks] = nil

            row
          end

          private

          attr_reader :target, :remark_start
        end
      end
    end
  end
end
