# frozen_string_literal: true

module Tms
  module Transforms
    module TextEntries
      class ToNote
        def initialize(target: :text_entry)
          @target = target
        end

        # @private
        def process(row)
          label = add_date(row, type_and_purpose(row))
          body = combine_label_and_note(row, label)
          row[target] = signed(row, body)
          row
        end

        private

        attr_reader :target

        def add_date(row, label)
          date = row.fetch(:textdate, nil)
          return label if date.blank?
          return date if label.blank?

          [label, date].join(', ')
        end

        def author(row)
          author_val = [
            row[:person_author],
            row[:org_author]
          ].reject{ |author| author.blank? }
          return nil if author_val.empty?

          author_val.join(', ')
        end

        def combine_label_and_note(row, label)
          val = [label, row.fetch(:textentry, nil)].reject{ |part| part.blank? }
          return nil if val.empty?

          val.join(': ')
        end

        def signed(row, body)
          val = [body, author(row)].reject{ |part| part.blank? }
          return nil if val.empty?

          val.join(' --')
        end

        def type_and_purpose(row)
          purpose = row.fetch(:purpose, '')
          type = row.fetch(:texttype, '')

          return nil if purpose.blank? && type.blank?

          purpose = '' if purpose.nil?
          type = '' if type.nil?

          return purpose if purpose.downcase[type.downcase]
          return type if type.downcase[purpose.downcase]

          [type, purpose].join(': ')
        end
      end
    end
  end
end
