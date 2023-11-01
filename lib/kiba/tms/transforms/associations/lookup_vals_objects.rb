# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Associations
        class LookupValsObjects < LookupVals
          def initialize
            @lookup = Tms.get_lookup(
              jobkey: :objects__number_lookup,
              column: :objectid
            )
          end

          def process(row)
            do_lookups(row)
            row
          end

          private

          attr_reader :lookup

          def do_lookup(row, n)
            id = row["id#{n}".to_sym]
            return if id.blank?

            mergerows = lookup[id]
            row["val#{n}".to_sym] = mergerows.map { |r| r[:objectnumber] }
              .compact
              .join(Tms.delim)
          end
        end
      end
    end
  end
end
