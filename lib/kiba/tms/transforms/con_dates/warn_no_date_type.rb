# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConDates
        # Add 'no date type in datedescription'to :warn field if :datedescription is empty
        class WarnNoDateType
          include Warnable
          
          def initialize
            @warning = 'no date type in datedescription'
            @target = :warn
          end

          # @private
          def process(row)
            type = row[:datedescription]
            return row unless type.blank?

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
