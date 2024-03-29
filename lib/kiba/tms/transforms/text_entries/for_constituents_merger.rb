# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module TextEntries
        class ForConstituentsMerger
          def initialize
            lookup = Tms::Mixins::MultiTableMergeable.get_merge_lookup(
              Tms::TextEntriesForConstituents
            )
            @merger = Merge::MultiRowLookup.new(
              lookup: lookup,
              keycolumn: :constituentid,
              fieldmap: {text_entry: :text_entry},
              delim: Tms.notedelim,
              sorter: Lookup::RowSorter.new(on: :sort, as: :to_i)
            )
          end

          # @private
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
