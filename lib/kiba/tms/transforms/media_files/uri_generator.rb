# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module MediaFiles
        # Generates :mediafileuri value in :media_files__cspace. Assumes there
        #   is a :media_files__file_path_lookup
        class UriGenerator
          def initialize
            @lookup = Tms.get_lookup(
              jobkey: :media_files__file_path_lookup,
              column: :norm
            )
            @merger = Merge::MultiRowLookup.new(
              lookup: lookup,
              keycolumn: :lookuppath,
              fieldmap: {mediafileuri: :filepath},
              delim: Tms.delim
            )
            @bases = Tms::MediaFiles.tms_path_bases
          end

          def process(row)
            row[:lookuppath] = norm_path(row)
            row = merger.process(row)
            row.delete(:lookuppath)

            row
          end

          private

          attr_reader :lookup, :merger, :bases

          def norm_path(row)
            val = row[:fullpath]
            return nil if val.blank?

            bases_removed(val).downcase
              .delete_prefix("\\\\")
              .tr("\\", "/")
          end

          def bases_removed(val)
            return val if bases.empty?

            bases.each{ |base| val = val.delete_prefix(base) }
            val
          end
        end
      end
    end
  end
end
