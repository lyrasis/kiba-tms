# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ThesXrefs
        class ForConstituentsTreatmentMergerGender
          include Tms::Transforms::ValueAppendable
          include Tms::Transforms::ValueCombiners

          def initialize
            @termsource = :termpreferred
            @termtarget = :term_gender
            @body_source_fields = [:remarks]
            @notetarget = :term_gender_note
            @labelsource = :thesxreftype
            @notedelim = "%CR%%CR%"
          end

          def process(row, mergerow)
            handle_term(row, mergerow)
            handle_note(row, mergerow)
            row
          end

          private

          attr_reader :termsource, :termtarget, :body_source_fields,
            :notetarget, :labelsource, :notedelim

          def handle_term(row, mergerow)
            term = mergerow[termsource]
            return row if term.blank?

            append_value(row, termtarget, term, Tms.delim)
          end

          def handle_note(row, mergerow)
            labelval = mergerow[labelsource]
            label = labelval.blank? ? nil : "#{labelval.capitalize} note"
            note = labeled_body(mergerow, label)
            return row if note.blank?

            append_value(row, notetarget, note, notedelim)
          end
        end
      end
    end
  end
end
