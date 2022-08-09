# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConDates
        # Add 'multiple values for birth or death date for constituent id' to :warn field
        class WarnMultiBirthDeathDate
          include Warnable
          
          def initialize
            @warning = 'multiple values for birth or death date for constituent id'
            @target = :warn
          end

          # @private
          def process(row)
            duplicate = row[:duplicate]
            return row if duplicate.blank?

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
