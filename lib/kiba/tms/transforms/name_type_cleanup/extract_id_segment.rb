# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameTypeCleanup
        class ExtractIdSegment
          def initialize(
            target:,
            segment:,
            source: :constituentid
          )
            @target = target
            @segment = segment
            @source = source
          end

          def process(row)
            row[target] = nil unless target == source
            orig = row[source]
            return row if orig.blank?

            segments = orig.split(".")
            result = extract_id(segments)
            row[target] = result
            row
          end

          private

          attr_reader :target, :segment, :source

          def extract_id(segments)
            if segment.is_a?(Integer)
              segments[segment]
            else
              segments.shift
              segments.join(".")
            end
          end
        end
      end
    end
  end
end
