# frozen_string_literal: true

module Tms
  module Transforms
    module TextEntries
      class ForLoansPrepper
        def initialize(target: :text_entry)
          @target = target
        end

        # @private
        def process(row)
          label = add_date(row, type_and_purpose(row))
          body = combine_label_and_note(row, label)
          full = append_remarks(row, body)
          row[target] = signed(row, full)
          row
        end

        private

        attr_reader :target
        def add_date(row, label)
          date = row.fetch(:textdate, nil)
          return label if date.blank?
          return date if label.blank?

          [label, date].join(", ")
        end

        def author(row)
          author_val = row[:authorname]
          return nil if author_val.blank?

          author_val
        end

        def combine_label_and_note(row, label)
          val = [label, row.fetch(:textentry, nil)].reject { |part|
            part.blank?
          }
          return nil if val.empty?

          val.join(": ")
        end

        def append_remarks(row, body)
          full = [body, row.fetch(:remarks)].reject { |part| part.blank? }
          return nil if full.empty?

          full.join("; ")
        end

        def signed(row, body)
          val = [body, author(row)].reject { |part| part.blank? }
          return nil if val.empty?

          val.join(" --")
        end

        def type_and_purpose(row)
          purpose = row.fetch(:purpose, "")
          type = row.fetch(:texttype, "")

          return nil if purpose.blank? && type.blank?

          purpose = "" if purpose.nil?
          type = "" if type.nil?

          purpose = purpose.sub("DOG", "Deed of Gift")

          return purpose if purpose.downcase[type.downcase]
          return type if type.downcase[purpose.downcase]

          [type, purpose].join(": ")
        end
      end
    end
  end
end
