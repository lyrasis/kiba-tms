# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module AltNums
        # Used in job that has an objects table as its source
        module TreatmentMergeable
          def altnum(row)
            row[Tms::AltNums.mergeable_value_field]
          end

          def numtype(row)
            row[Tms::AltNums.type_field_target]
          end

          def build_note(row, pattern)
            [altnum(row),
              build_parenthetical(row, pattern)].compact.join(" ")
          end

          def build_parenthetical(row, pattern)
            val = pattern.map { |part| send(part, row) }
              .compact
            return nil if val.empty?

            "(#{val.join("; ")})"
          end

          def remarks(row)
            val = row[Tms::AltNums.note_field]
            return nil if val.blank?

            val
          end

          def dates(row)
            vals = [row[:beginisodate], row[:endisodate]]
            return nil if vals.all?(&:nil?)

            [vals[0], "-", vals[1]].compact.join(" ")
          end
        end
      end
    end
  end
end
