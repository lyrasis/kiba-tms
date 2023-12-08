# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module TextEntries
        class ForObjectsTreatmentMergerViewersPersonalExpUntyped
          include Tms::Transforms::ValueAppendable
          include TreatmentMergeable

          def initialize
            @target = :te_viewerspersonalexperience
            @delim = Tms::Objects.viewerspersonalexperience_delim
          end

          def process(row, mergerow)
            note = prefixed_note(mergerow)

            append_value(row, target, note, delim)
            row
          end

          private

          attr_reader :target, :delim

          def prefix(row)
            "Untyped text entry"
          end
        end
      end
    end
  end
end
