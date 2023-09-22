# frozen_string_literal: true

module Tms
  module Transforms
    module TextEntries
      class ForExhObjXrefsMerger
        def initialize
          lookup = Tms::Mixins::MultiTableMergeable.get_merge_lookup(
            TextEntriesForExhObjXrefs
          )
          @merger = Merge::MultiRowLookup.new(
            lookup: lookup,
            keycolumn: :exhobjxrefid,
            fieldmap: {text_entry: :textentry},
            delim: Tms.delim
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
