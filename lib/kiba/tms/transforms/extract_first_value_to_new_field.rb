# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      class ExtractFirstValueToNewField
        def initialize(source:, newfield:, delim: Tms.delim)
          @source = source
          @newfield = newfield
          @delim = delim
        end

        def process(row)
          row[newfield] = nil
          val = row[source]
          return row if val.blank?

          vals = val.split(delim)
          if vals.length == 1
            row[newfield] = val
            row[source] = nil
          else
            row[newfield] = vals.shift
            row[source] = vals.join(delim)
          end
          row
        end

        private

        attr_reader :source, :newfield, :delim
      end
    end
  end
end
