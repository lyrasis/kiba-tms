# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module TextEntries
        class ForObjectsTreatmentMergerNoteObjectHistory
          include Tms::Transforms::ValueAppendable
          include TreatmentMergeable

          def initialize
            @target = :te_objecthistorynote
            @delim = Tms::Objects.objecthistorynote_delim
          end

          def process(row, mergerow)
            note = prefixed_note(mergerow)

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
