# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module AltNums
        # Used in job that has an objects table as its source
        class ForObjectsTreatmentMergerAltnumAnnotation
          include TreatmentMergeable

          def initialize
            prefix = "altnum"
            datafields = %i[annotationnote annotationtype]
            @numtarget = "#{prefix}_#{datafields[0]}".to_sym
            @typetarget = "#{prefix}_#{datafields[1]}".to_sym
            padfields = Tms::Objects.annotation_target_fields - datafields
            @padfields = padfields.map { |field| "#{prefix}_#{field}".to_sym }
            @delim = Tms.delim
            @note_builder = ->(mergerow) do
              build_note(mergerow, %i[numtype remarks dates])
            end
          end

          def process(row, mergerow)
            type = Tms::AltNums.for_objects_altnum_annotation_type
            note = note_builder.call(mergerow)
            append_value(row, typetarget, type, delim)
            append_value(row, numtarget, note, delim)
            padfields.each do |field|
              append_value(row, field, "%NULLVALUE%", delim)
            end

            row
          end

          private

          attr_reader :numtarget, :typetarget, :padfields, :delim, :note_builder
        end
      end
    end
  end
end
