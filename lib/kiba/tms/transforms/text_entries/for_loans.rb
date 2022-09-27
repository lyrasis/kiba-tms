# frozen_string_literal: true

module Tms
  module Transforms
    module TextEntries
      class ForLoans
        def initialize(target: :text_entry)
          @target = target
        end

        # @private
        def process(row)
          if row.key?(:remarks)
            msg = "#{self.class.name} includes unaccounted for `remarks` vals"
            warn(msg)
          end
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
          author_val = [row.fetch(:org_author, nil), row.fetch(:person_author, nil)].reject{ |author| author.blank? }
          return nil if author_val.empty?

          author_val.first
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

          purpose = purpose.sub('DOG', 'Deed of Gift')

          return purpose if purpose.downcase[type.downcase]
          return type if type.downcase[purpose.downcase]

          [type, purpose].join(': ')
        end
      end
    end
  end
end
