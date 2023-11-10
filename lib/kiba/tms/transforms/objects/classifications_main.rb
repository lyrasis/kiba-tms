# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Objects
        class ClassificationsMain
          def initialize
            @idfield = Tms::Classifications.id_field
            @mergemap = Tms::Classifications.object_merge_fieldmap
            lookup = Tms.get_lookup(
              jobkey: :prep__classifications,
              column: idfield
            )
            @merger = Merge::MultiRowLookup.new(
              lookup: lookup,
              keycolumn: idfield,
              fieldmap: mergemap,
              null_placeholder: "%NULLVALUE%"
            )
            @renamer = Rename::Fields.new(fieldmap: build_renamemap)
          end

          def process(row)
            merger.process(row)
            renamer.process(row)
            row.delete(idfield)
            row
          end

          private

          attr_reader :idfield, :mergemap, :merger, :renamer

          def build_renamemap
            mergemap.keys.map { |key| [key, "#{key}_main".to_sym] }
              .to_h
          end
        end
      end
    end
  end
end
