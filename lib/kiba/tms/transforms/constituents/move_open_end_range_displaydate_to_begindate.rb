# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        class MoveOpenEndRangeDisplaydateToBegindate
          include Tms::Transforms::FullerDateSelectable
          include Tms::Transforms::ValueAppendable

          def initialize
            @source = :displaydate
            @target = :begindateiso
          end

          def process(row)
            dd = row[source]
            return row unless eligible?(dd)

            val = dd.sub(/- *$/, "")
            begindate = row[target]
            begindate.blank? ? add(row, val) : compare(row, val, begindate)
            row[source] = nil
            row
          end

          private

          attr_reader :source, :prefix, :target

          def add(row, val)
            row[target] = val
          end

          def add_note(row, val)
            note = "Birth date from TMS displayDate: #{val}"
            append_value(row, :datenote, note, "%CR%%CR%")
          end

          def compare(row, val, begindate)
            fuller = select_fuller_date(val, begindate)
            fuller ? add(row, fuller) : add_note(row, val)
          end

          def eligible?(dd)
            return false if dd.blank?

            true if dd.downcase.match?(/- *$/)
          end
        end
      end
    end
  end
end
