# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      # Given fields containing year, month, and day parts, returns target field combining those values
      class DateFromParts
        
        def initialize(year:, month:, day:, target:)
          @year_f = year
          @month_f = month
          @day_f = day
          @target = target
          @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
            fields: [year_f, month_f, day_f], discard: []
          )
        end

        def process(row)
          row[target] = nil
          @vals = getter.call(row)
          return delete_sources(row) unless date_data?

          year = vals[year_f]
          if year.blank?
            warn("#{self.class.name}: Cannot create #{target} from #{vals.inspect}")
            return delete_sources(row)
          end

          month = vals[month_f]
          day = vals[day_f]
          if month.blank? && day.blank?
            row[target] = year
            return delete_sources(row)
          end

          if day.blank?
            row[target] = "#{year}-#{pad(month)}"
            return delete_sources(row)
          end

          if month.blank?
            warn("#{self.class.name}: Cannot create #{target} from #{vals.inspect}")
            return delete_sources(row)
          end

          row[target] = "#{year}-#{pad(month)}-#{pad(day)}"
          delete_sources(row)
        end

        private

        attr_reader :year_f, :month_f, :day_f, :target, :vals, :getter

        def date_data?
          vals.reject{ |_key, val| val.blank? }.empty? ? false : true
        end
        
        def delete_sources(row)
          [year_f, month_f, day_f].each{ |field| row.delete(field) }
          row
        end

        def pad(val)
          str = val.is_a?(String) ? val : val.to_s
          str.rjust(2, "0")
        end
      end
    end
  end
end
