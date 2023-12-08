# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module TextEntries
        class ForObjRightsTreatmentMergerRightNoteTypeprefix <
            ForObjRightsTreatmentMergerRightNote
          def note(mergerow)
            prefixed_note(mergerow)
          end
        end
      end
    end
  end
end
