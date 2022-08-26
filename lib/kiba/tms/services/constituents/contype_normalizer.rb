# frozen_string_literal: true

module Kiba
  module Tms
    module Services
      module Constituents
        class ContypeNormalizer
          def initialize
            @pattern = Regexp.new('\?| \(derived\)')
          end

          def call(value)
            return value if value.blank?
            
            value.sub(pattern, '')
          end

          private

          attr_reader :pattern
        end
      end
    end
  end
end
