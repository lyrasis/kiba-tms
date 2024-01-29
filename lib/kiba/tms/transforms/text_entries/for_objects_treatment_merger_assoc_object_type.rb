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
            append_value(row, objtarget, get_value(objsource, mergerow), delim)
            append_value(
              row, typetarget, get_value(typesource, mergerow), delim
            )
            append_value(row, notetarget, derive_note(mergerow), delim)

            row
          end

          private

          attr_reader :objsource, :objtarget, :typesource, :typetarget,
            :notetarget, :delim

          def get_value(field, mergerow)
            val = mergerow[field]
            val.blank? ? "%NULLVALUE%" : val
          end

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
