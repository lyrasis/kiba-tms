# frozen_string_literal: true

module Tms
  module Transforms
    module TextEntries
      class MergeLoanObjXrefs
        def initialize
          @merger = Merge::MultiRowLookup.new(
            lookup: Tms.get_lookup(
              jobkey: :text_entries_for__loan_obj_xrefs,
              column: :recordid
            ),
            keycolumn: :loanobjxrefid,
            fieldmap: {text_entry: :text_entry},
            delim: "%CR%"
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
