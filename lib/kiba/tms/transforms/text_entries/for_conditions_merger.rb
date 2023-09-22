# frozen_string_literal: true

module Tms
  module Transforms
    module TextEntries
      class ForConditionsMerger
        def initialize
          lookup = Tms::Mixins::MultiTableMergeable.get_merge_lookup(
            TextEntriesForConditions
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
