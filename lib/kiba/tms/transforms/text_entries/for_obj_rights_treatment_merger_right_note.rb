# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module TextEntries
        class ForObjRightsTreatmentMergerRightNote
          include Tms::Transforms::ValueAppendable
          include TreatmentMergeable

          def initialize
            @target = :te_rightnote
            @delim = Tms.notedelim
          end

          def process(row, mergerow)
            append_value(row, target, note(mergerow), delim)
            row
          end

          private

          attr_reader :target, :delim

          def note(mergerow)
            attributed_note(mergerow)
          end
        end
      end
    end
  end
end
