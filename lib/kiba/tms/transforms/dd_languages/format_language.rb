# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module DDLanguages
        class FormatLanguage

          def initialize
            @target = :language
          end

          def process(row)
            val = row[target]
            return row if val.blank?

            row[target] = val.downcase
              .capitalize
              .gsub('_', ' ')
              .strip
            row
          end

          private

          attr_reader :target
        end
      end
    end
  end
end
