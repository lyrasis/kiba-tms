# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module TextEntries
        module TermMasterThesMergeable
          def process(row, mergerow)
            note = prefixed_note(mergerow)
            append_value(row, target, note, delim)

            row
          end
        end
      end
    end
  end
end
