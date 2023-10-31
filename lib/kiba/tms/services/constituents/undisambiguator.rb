# frozen_string_literal: true

module Kiba
  module Tms
    module Services
      module Constituents
        # Removes Tms::Constituents.duplicate_disambiguation_string from name
        #   for comparison/deduplication against non-constituent prefname
        #   sourced names
        class Undisambiguator
          def initialize
            @pattern = get_pattern
          end

          def call(name)
            return name unless pattern

            name.sub(pattern, "")
          end

          private

          attr_reader :pattern

          def get_pattern
            str = Tms::Constituents.duplicate_disambiguation_string
            return nil if str.blank?

            fixed = str.sub("(", '\(')
              .sub(/%int%/, ".*")
              .sub(")", '\)')
            Regexp.new(fixed)
          end
        end
      end
    end
  end
end
