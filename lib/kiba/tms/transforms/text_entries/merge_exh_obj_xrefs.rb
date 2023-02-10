# frozen_string_literal: true

module Tms
  module Transforms
    module TextEntries
      class MergeExhObjXrefs
        def initialize
          lookup = Tms.get_lookup(
            jobkey: :text_entries_for__exh_obj_xrefs,
            column: :recordid
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
