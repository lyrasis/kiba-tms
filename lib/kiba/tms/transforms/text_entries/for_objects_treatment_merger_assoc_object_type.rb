# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module TextEntries
        class ForObjectsTreatmentMergerAssocObjectType
          include Tms::Transforms::ValueAppendable
          include TreatmentMergeable

          def initialize
            @objsource = :textentry
            @objtarget = :te_assocobject
            @typesource = :texttype
            @typetarget = :te_assocobjecttype
            @notetarget = :te_assocobjectnote
            @delim = Tms.delim
          end

          def process(row, mergerow)
            append_value(row, objtarget, mergerow[objsource], delim)
            append_value(row, typetarget, mergerow[typesource], delim)
            append_value(row, notetarget, derive_note(mergerow), delim)

            row
          end

          private

          attr_reader :objsource, :objtarget, :typesource, :typetarget,
            :notetarget, :delim

          def derive_note(mergerow)
            parts = [
              mergerow[:authorname],
              mergerow[:textdate]
            ].reject(&:blank?)
            parts.empty? ? "%NULLVALUE%" : parts.join(", ")
          end
        end
      end
    end
  end
end
