# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        class MoveLongFormDisplaydateRanges
          include Tms::Transforms::FullerDateSelectable
          include Tms::Transforms::ValueAppendable

          def initialize
            @source = :displaydate
            @birth = :begindateiso
            @death = :enddateiso
            @pattern = Regexp.new('^(\d{3,4}(?:-\d{1,2}){1,2}) *- *(\d{3,4}(?:-\d{1,2}){1,2})$')
          end

          def process(row)
            dd = row[source]
            return row unless eligible?(dd)

            matches = dd.match(pattern)

            %i[birth death].each_with_index do |type, idx|
              sourceval = matches[idx + 1]
              targetfield = send(type)
              targetdate = row[targetfield]
              if targetdate.blank?
                add(row, targetfield, sourceval)
              else
                fuller = select_fuller_date(sourceval, targetdate)
                if fuller
                  add(row, targetfield, fuller)
                else
                  add_note(row, type, sourceval)
                end
              end
            end

            row[source] = nil
            row
          end

          private

          attr_reader :source, :birth, :death, :pattern

          def add(row, targetfield, val)
            row[targetfield] = val
          end

          def add_note(row, type, val)
            note = "#{type.to_s.capitalize} date from TMS displayDate: #{val}"
            append_value(row, :datenote, note, "%CR%%CR%")
          end

          def eligible?(dd)
            return false if dd.blank?

            true if pattern.match?(dd)
          end
        end
      end
    end
  end
end
