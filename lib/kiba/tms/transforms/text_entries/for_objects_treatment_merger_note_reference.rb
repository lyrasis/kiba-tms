# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module TextEntries
        class ForObjectsTreatmentMergerNoteReference
          include Tms::Transforms::ValueAppendable
          include TreatmentMergeable

          def initialize
            @referencetarget = :te_referencecitationlocal
            @referencevalue = "%NULLVALUE%"
            @notetarget = :te_referencenote
            @delim = Tms.delim
          end

          def process(row, mergerow)
            note = attributed_note(mergerow)

            append_value(row, referencetarget, referencevalue, delim)
            append_value(row, notetarget, note, delim)
            row
          end

          private

          attr_reader :referencetarget, :referencevalue, :notetarget, :delim
        end
      end
    end
  end
end
