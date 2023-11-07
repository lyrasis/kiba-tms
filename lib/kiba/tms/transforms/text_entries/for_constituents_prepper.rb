# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module TextEntries
        class ForConstituentsPrepper
          def initialize
            @target = :text_entry
          end

          # @private
          def process(row)
            label_and_note = [label(row), note(row)].compact.join(": ")
            final = [label_and_note, author(row)].compact.join(" --")
            row[target] = final
            %i[purpose textdate textentry remarks texttype org_author
              person_author].each do |field|
              next unless row.key?(field)

              row.delete(field)
            end

            row
          end

          private

          attr_reader :target

          def author(row)
            vals = [row.fetch(:person_author, nil), row.fetch(:org_author, nil)]
              .reject { |val| val.blank? }

            return nil if vals.empty?

            vals.first
          end

          def date_the_label(row)
            label = purpose_type_for_label(row)
            date = row.fetch(:textdate, nil)
            return label if date.blank?

            label.blank? ? date : "#{label}, #{date}"
          end

          def entry(row)
            val = row.fetch(:textentry, "")
            return nil if val.blank?

            val
          end

          def label(row)
            val = date_the_label(row)
            return nil if val.blank?

            "#{val}"
          end

          def note(row)
            val = [entry(row), remarks(row)].compact
            return nil if val.empty?
            return val.first if val.length == 1

            val.join("#{Tms.notedelim}REMARKS ON NOTE: ")
          end

          def purpose_type_for_label(row)
            val = [row.fetch(:texttype, ""), row.fetch(:purpose, "")]
              .reject { |val| val.blank? }
              .join("/")
            return nil if val.blank?

            val
          end

          def remarks(row)
            val = row.fetch(:remarks, "")
            return nil if val.blank?

            val
          end
        end
      end
    end
  end
end
