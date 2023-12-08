# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module TextEntries
        class ForObjectsTreatmentMergerUsageExhibition
          include Tms::Transforms::ValueAppendable
          include TreatmentMergeable

          def initialize
            @usagetarget = :te_usage
            @usagevalue = "exhibition"
            @notetarget = :te_usagenote
            @delim = Tms.delim
          end

          def process(row, mergerow)
            note = attributed_note(mergerow)

            append_value(row, usagetarget, usagevalue, delim)
            append_value(row, notetarget, note, delim)
            row
          end

          private

          attr_reader :usagetarget, :usagevalue, :notetarget, :delim
        end
      end
    end
  end
end
