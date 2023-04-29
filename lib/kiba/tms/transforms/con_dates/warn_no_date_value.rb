# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConDates
        # Add "no date value" to :warn field if :date is blank
        class WarnNoDateValue
          include Warnable
          
          def initialize
            @target = :warn
            @warning = "no date value"
          end

          # @private
          def process(row)
            source = row[:datasource]
            return row unless source == "ConDates"
            
            date = row[:date]
            return row unless date.blank?

            add_warning(row)
            row
          end
          
          private

          attr_reader :target, :warning
        end
      end
    end
  end
end
