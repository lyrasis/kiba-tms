# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ObjLocations
        class HandleInactive
          def initialize
            @target = Tms::ObjLocations.inactive_treatment
            return if target == :ignore

            @action = set_action
            @delim = target == :currentlocationnote ? ' -- ' : "\n"
            @note = Tms::ObjLocations.inactive_note_string
          end

          def process(row)
            return row if target == :ignore

            if inactive?(row)
              process_inactive(row)
            else
              process_active(row)
            end
            row.delete(:inactive)
            row
          end

          private

          attr_reader :target, :action, :delim, :note

          def inactive?(row)
            row[:inactive] == '1'
          end

          def process_active(row)
            row[target] = nil if action == :newfield
          end

          def process_inactive(row)
            if action == :newfield
              row[target] = note
            else
              val = row[target]
              row[target] = "#{note}#{delim}#{val}"
            end
          end

          def set_action
            if Tms::ObjLocations.temptext_note_targets.any?(target)
              :prepend
            else
              :newfield
            end
          end
        end
      end
    end
  end
end
