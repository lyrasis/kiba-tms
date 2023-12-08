# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module TextEntries
        class ForObjectsTreatmentMergerNoteCopyright
          include Tms::Transforms::ValueAppendable
          include TreatmentMergeable

          def initialize
            @target = :te_copyright
            @delim = Tms.notedelim
          end

          def process(row, mergerow)
            note = attributed_note(mergerow)

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
