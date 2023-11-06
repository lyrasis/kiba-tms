# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Associations
        module Lookupable
          def process(row)
            do_lookups(row)
            row
          end

          def do_lookups(row)
            [1, 2].each { |n| do_lookup(row, n) }
          end
        end
      end
    end
  end
end
