# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ObjTitles
        class TitleNoteCreator
          def initialize
            @target = :titlenote
            @content_fields = %i[remarks dateeffectiveisodate] - Tms::ObjTitles.empty_fields.keys
            @context_fields = %i[titletype title]
            @contentgetter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: content_fields
            )
            @contextgetter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: context_fields
            )
          end

          # @private
          def process(row)
            row[target] = nil
            content = contentgetter.call(row)
            if content.empty?
              delete_content(row)
              return row
            end

            row[target] = note(row, content)
            delete_content(row)
            row
          end
          
          private

          attr_reader :target, :content_fields, :context_fields, :contentgetter, :contextgetter

          def date_label(context)
            return "#{context[:titletype].capitalize} title #{title(context)} effective" if context.key?(:titletype)

            "Title #{title(context)} effective"
          end

          def delete_content(row)
            content_fields.each{ |field| row.delete(field) }
          end
          
          def note(row, content)
            [
              note_label(content, contextgetter.call(row)),
              note_content(content)
            ].join(': ')
          end

          def note_content(content)
            transform_date(content) if content.keys.any?(:dateeffectiveisodate)
            content.values.join('; ')
          end

          def note_label(content, context)
            content.key?(:remarks) ? remarks_label(context) : date_label(context)
          end

          def remarks_label(context)
            intro = context.key?(:titletype) ? "Note for #{context[:titletype]} title" : 'Note for title'
            "#{intro} #{title(context)}"
          end

          def title(context)
            "(#{context[:title]})"
          end
          
          def transform_date(content)
            date = content[:dateeffectiveisodate]
            if content.key?(:remarks)
              content[:dateeffectiveisodate] = "Title effective: #{date}"
            end
          end
        end
      end
    end
  end
end
