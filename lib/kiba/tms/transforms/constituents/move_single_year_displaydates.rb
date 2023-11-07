# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        class MoveSingleYearDisplaydates
          include Tms::Transforms::FullerDateSelectable
          include Tms::Transforms::ValueAppendable

          def initialize
            @source = :displaydate
            @target = :begindateiso
          end

          def process(row)
            dd = row[source]
            return row unless eligible?(dd)

            begindate = row[target]
            begindate.blank? ? add(row, dd) : compare(row, dd, begindate)
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
            append_value(row, :datenote, note, Tms.notedelim)
          end

          def compare(row, val, begindate)
            numonly = val.match(/(\d+)/)[1]
            fuller = select_fuller_date(numonly, begindate)
            if fuller
              add(row, val) if fuller == numonly
            else
              add_note(row, val)
            end
          end

          def eligible?(dd)
            return false if dd.blank?
            return false if dd.split("-").length > 1

            true if dd.downcase.match?(/^(\d{2,4}|ca?\.? ?\d)/)
          end
        end
      end
    end
  end
end
