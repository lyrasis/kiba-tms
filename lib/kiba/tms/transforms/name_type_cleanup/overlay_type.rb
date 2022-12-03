# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameTypeCleanup
        class OverlayType
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
          # @param source [Symbol] field containing corrected type code
          def initialize(target:,
                         source: :correctauthoritytype)
            @target = target
            @source = source
          end

          def process(row)
            corrtype = row[source]
            return row if corrtype.blank?

            return row unless eligible?(row)

            case corrtype
            when 'p'
              val = 'Person'
            when 'o'
              val = 'Organization'
            when 'n'
              val = 'Note'
            else
              fail(Tms::UnknownAuthorityTypeCode, corrtype)
            end

            row[row_target(row)] = val
            row
          end

          private

          attr_reader :target, :source
        end
      end
    end
  end
end
