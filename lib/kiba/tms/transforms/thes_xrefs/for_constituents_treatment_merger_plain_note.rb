# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ThesXrefs
        class ForConstituentsTreatmentMergerPlainNote
          include Tms::Transforms::ValueAppendable
          include Tms::Transforms::ValueCombiners
          def initialize
            @target = :term_plain_note
            @body_source_fields = %i[termused remarks]
            @body_delim = " -- "
            @note_delim = Tms.notedelim
            @label = "Untyped note"
          end

          def process(row, mergerow)
            note = labeled_body(mergerow, label)
            append_value(row, target, note, note_delim)
            row
          end

          private

          attr_reader :target, :body_source_fields, :body_delim, :note_delim,
            :label
        end
      end
    end
  end
end
