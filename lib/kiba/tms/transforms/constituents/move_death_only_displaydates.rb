# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        class MoveDeathOnlyDisplaydates
          include Tms::Transforms::FullerDateSelectable
          include Tms::Transforms::ValueAppendable

          def initialize
            @source = :displaydate
            @target = :enddateiso
            @prefixes = Tms::Constituents.dates.datedescription_variants["death"]
              .map { |prefix|
              Regexp.new("^#{prefix} *", Regexp::IGNORECASE)
            }
          end

          def process(row)
            dd = row[source]
            return row unless eligible?(dd)

            val = dd.sub(prefix(dd), "")
            targetdate = row[target]
            targetdate.blank? ? add(row, val) : compare(row, val, targetdate)
            row[source] = nil
            row
          end

          private

          attr_reader :source, :prefixes, :target

          def add(row, val)
            row[target] = val
          end

          def add_note(row, val)
            note = "Death date from TMS displayDate: #{val}"
            append_value(row, :datenote, note, "%CR%%CR%")
          end

          def compare(row, val, targetdate)
            numonly = val.match(/(\d+)/)[1]
            fuller = select_fuller_date(numonly, targetdate)
            if fuller
              add(row, val) if fuller == numonly
            else
              add_note(row, val)
            end
          end

          def prefix(dd)
            prefixes.select { |prefix| dd.match?(prefix) }
              .sort_by { |prefix| prefix.to_s.length }
              .last
          end

          def eligible?(dd)
            return false if dd.blank?

            true if prefixes.any? { |prefix| dd.match?(prefix) }
          end
        end
      end
    end
  end
end
