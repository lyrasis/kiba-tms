# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        class MoveRemainingDisplaydatesToNotes
          include Tms::Transforms::ValueAppendable

          def initialize
            @source = :displaydate
            @target = :datenote
          end

          def process(row)
            dd = row[source]
            return row unless eligible?(dd)

            note = "Unparseable date info from TMS displayDate: #{dd}"
            append_value(row, :datenote, note, "%CR%%CR%")
            row[source] = nil
            row
          end

          private

          attr_reader :source, :target

          def eligible?(dd)
            return false if dd.blank?

            true
          end
        end
      end
    end
  end
end
