# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Associations
        # Creates 2 rows from each row:
        #
        # id1 rel1 lookupValueForId2
        # id2 rel2 lookupValueForId1
        class Explode
          def initialize
            @rows = []
          end

          # @private
          def process(row)
            make_new_row

            nil
          end

          def close
            rows.each { |r| yield r }
          end

          private

          attr_reader :rows

          def make_new_row(n, row)
            exrow = row.dup
          end
        end
      end
    end
  end
end
