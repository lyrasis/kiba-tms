# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module RefXRefs
        class NoteBuilder
          def initialize
            @target = :referencenote
            @notefields = %i[illustrated appendage pagenumber cataloguenumber
              figurenumber remarks]
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: notefields
            )
            @deleter = Delete::Fields.new(fields: notefields)
            @illmap = Tms::RefXRefs.illustrated_mapping
          end

          def process(row)
            vals = getter.call(row)
            row[target] = build_note(vals)
            deleter.process(row)
            row
          end

          private

          attr_reader :target, :notefields, :getter, :deleter, :illmap

          def build_note(vals)
            subcite = [
              vals[:appendage],
              vals[:pagenumber],
              vals[:cataloguenumber],
              vals[:figurenumber]
            ].compact
              .join(", ")
            ill = illmap[vals[:illustrated]]
            [subcite, ill, vals[:remarks]].compact
              .reject(&:empty?)
              .join(". ")
          end
        end
      end
    end
  end
end
