# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module AltNums
        # Used in job that has an objects table as its source
        class ForObjectsTreatmentMergerAltnumAnnotation
          include TreatmentMergeable

          def initialize
            @numtarget = :altnum_annotationnote
            @typetarget = :altnum_annotationtype
            @delim = Tms.delim
            @note_builder = ->(mergerow) do
              build_note(mergerow, %i[numtype remarks dates])
            end
          end

          def process(row, mergerow)
            type = Tms::AltNums.for_objects_altnum_annotation_type

            fresh?(row) ? add(row, mergerow, type) : append(row, mergerow, type)
            row
          end

          private

          attr_reader :numtarget, :typetarget, :delim, :note_builder

          def fresh?(row)
            true unless row.keys.include?(numtarget)
          end

          def add(row, mergerow, type)
            row[typetarget] = type
            row[numtarget] = note_builder.call(mergerow)
            row
          end

          def append(row, mergerow, type)
            row[typetarget] = [row[typetarget], type].join(delim)

            row[numtarget] = [
              row[numtarget],
              note_builder.call(mergerow)
            ].join(delim)
            row
          end
        end
      end
    end
  end
end
