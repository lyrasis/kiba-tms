# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameTypeCleanup
        class OverlayAll
          def initialize(typetarget: :contype,
            nametarget: Tms::Constituents.preferred_name_field)
            @typetarget = typetarget
            @nametarget = nametarget
            @dropper = OverlayDrop.new(
              target: nametarget
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
            if row[:correctauthoritytype] == "d"
              dropper.process(row)
            else
              typeoverlayer.process(row)
              nameoverlayer.process(row)
            end
            deleter.process(row)
            row
          end

          private

          attr_reader :typetarget, :nametarget,
            :merger, :dropper, :typeoverlayer, :nameoverlayer,
            :deleter
        end
      end
    end
  end
end
