# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Objects
        class ClassificationsXrefs
          def initialize
            @idfield = Tms::Classifications.id_field
            @mergemap = Tms::Classifications.object_merge_fieldmap
            lookup = Tms.get_lookup(
              jobkey: :classification_xrefs_for__objects,
              column: idfield
            )
            @merger = Merge::MultiRowLookup.new(
              lookup: lookup,
              keycolumn: :objectid,
              fieldmap: mergemap,
              conditions: ->(row, mergerows) do
                mainval = row[:classification_main]
                mergerows.reject { |r| r[:classification] == mainval }
              end,
              null_placeholder: "%NULLVALUE%",
              sorter: Lookup::RowSorter.new(
                on: :sort, as: :to_i
              )
            )
            @renamer = Rename::Fields.new(fieldmap: build_renamemap)
          end

          def process(row)
            merger.process(row)
            renamer.process(row)
            row
          end

          private

          attr_reader :idfield, :mergemap, :merger, :renamer

          def build_renamemap
            mergemap.keys.map { |key| [key, "#{key}_xref".to_sym] }
              .to_h
          end
        end
      end
    end
  end
end
