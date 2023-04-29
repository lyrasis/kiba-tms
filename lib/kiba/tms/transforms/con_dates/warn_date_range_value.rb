# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConDates
        # Add "range date value" to :warn field if :date contains ' - ' and :datedescription is not 'active'
        class WarnDateRangeValue
          include Warnable

          def initialize
            @warning = "date value is range"
            @target = :warn
          end

          # @private
          def process(row)
            type = row[:datedescription]
            return row if type.blank?
            return row if type == "active"

            date = row[:date]
            return row if date.blank?
            return row unless date[" - "]

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
