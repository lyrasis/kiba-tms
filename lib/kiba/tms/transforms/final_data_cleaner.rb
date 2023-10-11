# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      class FinalDataCleaner
        def initialize(fields: :all)
          @replacers = [
            Clean::RegexpFindReplaceFieldVals.new(
              fields: fields,
              find: "%QUOT%",
              replace: '"'
            ),
            Clean::RegexpFindReplaceFieldVals.new(
              fields: fields,
              find: "%CR%",
              replace: "\n"
            )
          ]
        end

        def process(row)
          replacers.each { |replacer| replacer.process(row) }
          row
        end

        private

        attr_reader :replacers
      end
    end
  end
end
