# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        class Merger
          def initialize(lookup:, keycolumn:, targets:)
            @mergers = targets.map do |target, src|
                Merge::MultiRowLookup.new(
                  lookup: lookup,
                  keycolumn: keycolumn,
                  fieldmap: {target => src}
                )
            end
            @deleter = Delete::Fields.new(fields: keycolumn)
          end

          def process(row)
            mergers.each{ |merger| merger.process(row) }
            deleter.process(row)
            row
          end

          private

          attr_reader :mergers, :deleter
        end
      end
    end
  end
end
