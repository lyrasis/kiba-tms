# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module MediaXrefs
        class ForLoansPrepper
          def initialize
            @merger = Merge::MultiRowLookup.new(
              lookup: Tms.get_lookup(
                jobkey: :loans__in_lookup,
                column: :loanid
              ),
              keycolumn: :id,
              fieldmap: {loanin: :loanid}
            )
          end

          def process(row)
            merger.process(row)
            row
          end

          private

          attr_reader :merger
        end
      end
    end
  end
end
