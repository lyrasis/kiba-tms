# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module TextEntries
        class ForObjectsTreatmentMergerOtherNumber
          include Tms::Transforms::ValueAppendable
          include TreatmentMergeable

          def initialize
            @numbertarget = :te_numbervalue
            @typetarget = :te_numbertype
            @typesource = :texttype
            @delim = Tms.delim
          end

          def process(row, mergerow)
            numvalue = attributed_note(mergerow)

            append_value(row, numbertarget, numvalue, delim)
            append_value(row, typetarget, mergerow[typesource], delim)
            row
          end

          private

          attr_reader :numbertarget, :typetarget, :typesource, :delim
        end
      end
    end
  end
end
