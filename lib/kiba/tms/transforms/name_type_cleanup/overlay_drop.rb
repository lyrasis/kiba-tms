# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameTypeCleanup
        class OverlayDrop
          include Overlayable
          # @param target [Symbol, Hash{Symbol=>Symbol}] indication of field (or
          #   row relation_type/field combination in which to update the value.
          #
          # If a Symbol is given, value in that field is updated if the field
          #   exists.
          #
          # If Hash given, format is:
          #
          # ```
          #   {
          #     relation_type => targetfieldname,
          #     another_relation_type => differentfieldname
          #   }
          # ```
          # @param source [Symbol] field containing corrected name
          def initialize(target:)
            @target = target
            @val = if Tms.migration_status == :dev
              Tms::Names.dropped_name_indicator
            end
          end

          def process(row)
            return row unless eligible?(row)

            row[row_target(row)] = val
            row
          end

          private

          attr_reader :target, :val
        end
      end
    end
  end
end
