# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module TextEntries
        class ForObjectsTreatmentMergerInscriptionInterpretationTypeprefix
          include ForObjectsInscribable
          include Tms::Transforms::ValueAppendable

          def initialize
            @targets = %i[inscriptioncontentinterpretation]
            @prefix = :te
            prefixed = prefix_fields(targets)
            @to_pad = get_to_pad
            @notetarget = prefixed[0]
            @notesource = :textentry
            @noteprefixsource = :texttype
            @delim = Tms.delim
          end

          def process(row, mergerow)
            append_value(row, notetarget, derive_interp(mergerow), delim)
            pad(row)
            row
          end

          private

          attr_reader :targets, :prefix, :notetarget, :notesource,
            :noteprefixsource, :delim, :to_pad

          def derive_interp(mergerow)
            body = [
              mergerow[noteprefixsource],
              mergerow[notesource]
            ].reject(&:blank?)
              .join(": ")
            attrib = derive_note(mergerow)
            return body if attrib == "%NULLVALUE%"

            [body, attrib].join(" --")
          end
        end
      end
    end
  end
end
