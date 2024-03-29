# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module DDLanguages
        class FormatLanguage
          def initialize
            @target = Tms::DDLanguages.type_field
          end

          def process(row)
            val = row[target]
            return row if val.blank?

            row[target] = val.downcase
              .capitalize
              .tr("_", " ")
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
