# frozen_string_literal: true

module Tms
  module Transforms
    module TextEntries
      class MergeConditions
        def initialize
          lookup = Tms.get_lookup(
            jobkey: :text_entries_for__conditions,
            column: :recordid
          )
          prefix = "te"
          datetarget = "#{prefix}_conditiondate".to_sym
          notetarget = "#{prefix}_conditionnote".to_sym
          @merger = Merge::MultiRowLookup.new(
            lookup: lookup,
            keycolumn: :conditionid,
            fieldmap: {
              notetarget => :text_entry,
              datetarget => :textdate
            },
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
