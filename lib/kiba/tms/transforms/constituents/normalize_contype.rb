# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        # for use on tables to merge with constituents on constituentid
        class NormalizeContype
          def initialize(source: :contype, target: :contype_norm)
            @source = source
            @target = target
          end

          # @private
          def process(row)
            row[target] = nil
            type = row[source]
            return row if type.blank?
            
            row[target] = type.sub(/\?| \(derived\)/, '')
            row
          end
          
          private

          attr_reader :source, :target
        end
      end
    end
  end
end
