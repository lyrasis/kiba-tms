# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConDisplayBios
        class Merger
          def initialize
            @lookup = Tms.get_lookup(
              jobkey: :prep__con_display_bios,
              column: :constituentid
            )
            @xforms = [
              Merge::MultiRowLookup.new(
                lookup: lookup,
                keycolumn: :constituentid,
                fieldmap: {displayed_bio: :bio},
                conditions: ->(_con, rows) do
                  rows.select do |row|
                    disp = row[:isdisplayed]
                    disp && disp == "1"
                  end
                end,
                delim: Tms.notedelim
              )
            ]
            if Tms::ConDisplayBios.migrate_non_displayed
              @xforms << Merge::MultiRowLookup.new(
                lookup: lookup,
                keycolumn: :constituentid,
                fieldmap: {undisplayed_bio: :bio},
                conditions: ->(_con, rows) do
                  rows.select do |row|
                    disp = row[:isdisplayed]
                    disp && disp == "0"
                  end
                end,
                delim: Tms.notedelim
              )
            end
          end

          def process(row)
            xforms.each { |xform| xform.process(row) }
            row
          end

          private

          attr_reader :lookup, :xforms
        end
      end
    end
  end
end
