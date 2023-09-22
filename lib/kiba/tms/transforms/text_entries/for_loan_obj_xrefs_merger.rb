# frozen_string_literal: true

module Tms
  module Transforms
    module TextEntries
      class ForLoanObjXrefsMerger
        def initialize
          lookup = Tms::Mixins::MultiTableMergeable.get_merge_lookup(
            TextEntriesForLoanObjXrefs
          )
          @merger = Merge::MultiRowLookup.new(
            lookup: lookup,
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
