# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module TextEntries
        class ForObjectsTreatmentMergerAnnotationType
          include Tms::Transforms::ValueAppendable
          include TreatmentMergeable

          def initialize
            @namemerger = Tms::Transforms::Constituents::Merger.new(
              lookup: Tms.get_lookup(
                jobkey: :names__by_constituentid,
                column: :constituentid
              ),
              keycolumn: :authorconid,
              targets: {
                org_author: :org,
                person_author: :person
              }
            )
            @typetarget = :te_annotationtype
            @typesource = :texttype
            @notetarget = :te_annotationnote
            @notesource = :textentry
            @datetarget = :te_annotationdate
            @datesource = :textdate
            @authortarget = :te_annotationauthor
            @authorsource = :person_author
            @delim = Tms.delim
          end

          def process(row, mergerow)
            namemerger.process(mergerow) unless mergerow[:authorconid].blank?

            append_value(row, typetarget, mergerow[typesource], delim)
            append_value(row, notetarget, derive_note(mergerow), delim)
            append_value(row, datetarget, derive_date(mergerow), delim)
            append_value(row, authortarget, derive_author(mergerow), delim)

            row
          end

          private

          attr_reader :namemerger, :typetarget, :typesource, :notetarget,
            :notesource, :datetarget, :datesource, :authortarget, :authorsource,
            :delim

          def derive_note(mergerow)
            [
              mergerow[notesource],
              mergerow[:org_author]
            ].reject(&:blank?)
              .join(" --")
          end

          def derive_date(mergerow)
            dateval = mergerow[datesource]
            dateval.blank? ? "%NULLVALUE%" : dateval
          end

          def derive_author(mergerow)
            authorval = mergerow[authorsource]
            authorval.blank? ? "%NULLVALUE%" : authorval
          end
        end
      end
    end
  end
end
