# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module TextEntries
        class ForReferenceMasterTreatmentMergerCitationNoteUntyped
          include TreatmentMergeable

          def initialize
            @target = :te_citation_note
            @delim = "%CR%%CR%"
          end

          def process(row, mergerow)
            note = attributed_note(mergerow)
            fresh?(row) ? add(row, note) : append(row, note)
            row
          end

          private

          attr_reader :target, :delim

          def fresh?(row)
            true unless row.key?(target)
          end

          def add(row, note)
            row[target] = note
            row
          end

          def append(row, note)
            row[target] = [row[target], note].join(delim)
            row
          end
        end
      end
    end
  end
end
