# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        class MoveLongFormSingleDisplaydates
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
            append_value(row, :datenote, note, '%CR%%CR%')
          end

          def compare(row, val, begindate)
            fuller = select_fuller_date(val, begindate)
            fuller ? add(row, fuller) : add_note(row, val)
          end
          
          def eligible?(dd)
            return false if dd.blank?

            true if dd.match?(/^\d{3,4}(-\d{1,2}){1,2}$/)
          end
        end
      end
    end
  end
end
