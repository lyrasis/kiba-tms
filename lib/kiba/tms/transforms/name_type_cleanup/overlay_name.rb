# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameTypeCleanup
        class OverlayName
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
          def initialize(target:,
            source: :correctname)
            @target = target
            @source = source
          end

          def process(row)
            return row unless eligible?(row)

            corrname = row[source]
            return row if corrname.blank?

            row[row_target(row)] = corrname
            row
          end

          private

          attr_reader :target, :source
        end
      end
    end
  end
end
