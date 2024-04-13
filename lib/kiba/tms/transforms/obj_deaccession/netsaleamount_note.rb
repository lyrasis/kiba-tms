# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ObjDeaccession
        class NetsaleamountNote
          def initialize
            @sources = %i[estimatelow estimatehigh]
            @target = :estimatenote
            @prefix = "Estimate range:"
          end

          def process(row)
            row[target] = nil
            vals = sources.map { |src| row[src] }
              .map { |val| val || "" }
            return row if vals.all?(&:empty?)

            range = vals.join(" - ")
            row[target] = [prefix, range].join(" ")
            row
          end

          private

          attr_reader :sources, :target, :prefix
        end
      end
    end
  end
end
