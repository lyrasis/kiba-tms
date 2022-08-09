# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConDates
        # Add "unknown/unmapped date type in datedescription" to :warn field
        class WarnUnknownDateType
          include Warnable
          
          def initialize
            @warning = 'unknown/unmapped date type in datedescription'
            @target = :warn
          end

          # @private
          def process(row)
            type = row[:datedescription]
            return row if type.blank?
            return row if Tms::Constituents.dates.known_types.any?(type)
            
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
