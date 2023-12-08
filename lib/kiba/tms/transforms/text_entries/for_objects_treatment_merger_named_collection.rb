# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module TextEntries
        class ForObjectsTreatmentMergerNamedCollection
          include Tms::Transforms::ValueAppendable
          include TreatmentMergeable

          def initialize
            @target = :te_named_collection
            @delim = Tms.delim
          end

          def process(row, mergerow)
            note = entry(mergerow)

            append_value(row, target, note, delim)
            row
          end

          private

          attr_reader :target, :delim
        end
      end
    end
  end
end
