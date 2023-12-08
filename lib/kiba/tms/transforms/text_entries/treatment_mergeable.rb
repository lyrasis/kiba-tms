# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module TextEntries
        module TreatmentMergeable
          def prefixed_note(row)
            parts = [prefix(row), attributed_note(row)].compact
            return nil if parts.empty?

            parts.join(": ")
          end

          def prefix(row)
            type = texttype(row)
            return nil if type.blank?

            type.capitalize
          end

          def texttype(row)
            val = row[Tms::TextEntries.type_field]
            return nil if val.blank?

            val
          end

          def attributed_note(row)
            parts = [entry(row), attribution(row)].compact
            return nil if parts.empty?

            parts.join(" --")
          end

          def entry(row)
            val = row[Tms::TextEntries.mergeable_value_field]
            return nil if val.blank?

            val
          end

          def attribution(row)
            parts = [authors(row), row[:textdate]].compact
            return nil if parts.empty?

            parts.join(", ")
          end

          def authors(row)
            parts = [row[:authorname]].compact
            # parts = [row[:person_author], row[:org_author]].compact
            return nil if parts.empty?

            parts.join(", ")
          end
        end
      end
    end
  end
end
