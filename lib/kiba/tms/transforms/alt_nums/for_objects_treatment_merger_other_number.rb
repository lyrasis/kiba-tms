# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module AltNums
        # Used in job that has an objects table as its source
        class ForObjectsTreatmentMergerOtherNumber
          include TreatmentMergeable

          def initialize
            @numtarget = :altnum_numbervalue
            @typetarget = :altnum_numbertype
            @delim = Tms.delim
          end

          def process(row, mergerow)
            num = altnum(mergerow)
            typeval = numtype(mergerow)
            type = typeval.blank? ? "%NULLVALUE%" : typeval

            append_value(row, typetarget, type, delim)
            append_value(row, numtarget, num, delim)
            row
          end

          private

          attr_reader :numtarget, :typetarget, :delim
        end
      end
    end
  end
end
