# frozen_string_literal: true

require 'emendate'

module Kiba
  module Tms
    module Transforms
      module ConDates
        # Add 'unparseable date value' to :warn field
        class DateParser
          include Warnable
          
          def initialize
            @warning = 'unparseable date value'
            @target = :warn
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: %i[birth_foundation_date death_dissolution_date]
              )
          end

          # @private
          def process(row)
            row[:date_parser_warnings] = nil
            row[:parsed_date_start] = nil
            row[:parsed_date_end] = nil
            
            vals = getter.call(row)
            return row if vals.empty?

            val = vals.values.first
            begin
              parsed = Emendate.parse(val)
            rescue StandardError
              add_warning(row, ' - Emendate application error')
              return row
            end

            if parsed.errors.length > 0
              add_warning(row, ' - Emendate parsing error')
            elsif unparseable_warnings(parsed)
              add_warning(row, ' - Emendate untokenizable')
            else
              row[:date_parser_warnings] = parsed.warnings.join('; ') unless parsed.warnings.empty?
              row[:parsed_date_start] = parsed.dates.map(&:date_start_full).join('|')
              row[:parsed_date_end] = parsed.dates.map(&:date_end_full).join('|')
            end

            row
          end
          
          private

          attr_reader :target, :warning, :getter

          def unparseable_warnings(parsed)
            warnings = parsed.warnings
            return false if warnings.empty?

            unparseable = warnings.select{ |warn| warn.start_with?('Untokenizable ') }
            true unless unparseable.empty?
          end
        end
      end
    end
  end
end
