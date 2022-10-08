# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameTypeCleanup
        class OverlayAll
          def initialize(lookup:,
                         typetarget: :contype,
                         nametarget: Tms::Constituents.preferred_name_field
                        )
            @typetarget = typetarget
            @nametarget = nametarget
            @merger = Merge::MultiRowLookup.new(
              lookup: lookup,
              keycolumn: :constituentid,
              fieldmap: {
                correctname: :correctname,
                correctauthoritytype: :correctauthoritytype
              }
            )
            @typeoverlayer = OverlayType.new(
              target: typetarget
              )
            @nameoverlayer = OverlayName.new(
              target: nametarget
            )
            @deleter = Delete::Fields.new(
              fields: %i[correctname correctauthoritytype]
            )
          end

          def process(row)
            merger.process(row)
            return if row[:correctauthoritytype] == 'd'

            typeoverlayer.process(row)
            nameoverlayer.process(row)
            deleter.process(row)
            row
          end

          private

          attr_reader :typetarget, :nametarget,
            :merger, :typeoverlayer, :nameoverlayer, :deleter
        end
      end
    end
  end
end
