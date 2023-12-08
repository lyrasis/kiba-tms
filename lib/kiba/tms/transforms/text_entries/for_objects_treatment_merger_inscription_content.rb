# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module TextEntries
        class ForObjectsTreatmentMergerInscriptionContent
          include ForObjectsInscribable
          include Tms::Transforms::ValueAppendable

          def initialize
            @targets = %i[inscriptioncontent inscriptioncontenttype
              inscriptioncontentinterpretation]
            @prefix = :te
            prefixed = prefix_fields(targets)
            @to_pad = get_to_pad
            @contentsource = :textentry
            @contenttarget = prefixed[0]
            @typeval = "inscribed"
            @typetarget = prefixed[1]
            @notetarget = prefixed[2]
            @delim = Tms.delim
          end

          def process(row, mergerow)
            append_value(row, contenttarget, mergerow[contentsource], delim)
            append_value(row, typetarget, typeval, delim)
            append_value(row, notetarget, derive_note(mergerow), delim)
            pad(row)
            row
          end

          private

          attr_reader :targets, :prefix, :contentsource, :contenttarget,
            :typeval, :typetarget, :notetarget, :delim, :to_pad
        end
      end
    end
  end
end
