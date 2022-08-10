# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        class MoveYearDisplaydateRanges
          include Tms::Transforms::FullerDateSelectable
          include Tms::Transforms::ValueAppendable
          
          def initialize
            @source = :displaydate
            @birth = :begindateiso
            @death = :enddateiso
          end
          
          def process(row)
            dd = row[source]
            return row unless eligible?(dd)

            parts = dd.split('-').map(&:strip)

            %i[birth death].each_with_index do |type, idx|
              sourceval = parts[idx]
              targetfield = self.send(type)
              targetdate = row[targetfield]
              if targetdate.blank?
                add(row, targetfield, sourceval)
              else
                binding.pry if sourceval.nil?
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

          attr_reader :source, :birth, :death

          def add(row, targetfield, val)
            row[targetfield] = val
          end

          def add_note(row, type, val)
            note = "#{type.to_s.capitalize} date from TMS displayDate: #{val}"
            append_value(row, :datenote, note, '%CR%%CR%')
          end
          
          def eligible?(dd)
            return false if dd.blank?
            parts = dd.split('-')
            return false unless parts.length == 2

            true if parts.select{ |part| part.match?(/(\d{4}|\d ?b\.?c\.?)/i) }.length == 2
          end
        end
      end
    end
  end
end
