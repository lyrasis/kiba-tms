# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ThesXrefs
        class ForConstituentsTreatmentMergerTypeLabeledNote
          include Tms::Transforms::ValueAppendable
          include Tms::Transforms::ValueCombiners

          def initialize
            @labelsource = :thesxreftype
            @termsource = :termused
            @notesource = :remarks
            @notedelim = "%CR%%CR%"
            @omittable_terms = Tms::ThesXrefs.constituents_omit_terms
          end

          def process(row, mergerow, suffix:, type:)
            target = "term_#{type}_note_#{suffix}".to_sym
            note = build_note(mergerow)
            append_value(row, target, note, notedelim)
            row
          end

          private

          attr_reader :labelsource, :termsource, :notesource, :notedelim,
            :omittable_terms

          def build_note(row)
            termval = row[termsource]
            term = omittable_terms.include?(termval) ? nil : termval
            thebody = safe_join(
              vals: [term, row[notesource]],
              delim: " -- "
            )
            return nil if thebody.empty?

            safe_join(
              vals: [row[labelsource], thebody],
              delim: ": "
            )
          end
        end
      end
    end
  end
end
