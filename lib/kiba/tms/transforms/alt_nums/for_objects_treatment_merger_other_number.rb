# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module AltNums
        # Used in job that has an objects table as its source
        class ForObjectsTreatmentMergerOtherNumber
          include TreatmentMergeable

          def initialize
            @numtarget = :othernumber_value
            @typetarget = :othernumber_type
            @delim = Tms.delim
          end

          def process(row, mergerow)
            num = altnum(mergerow)
            typeval = numtype(mergerow)
            type = typeval.blank? ? "%NULLVALUE%" : typeval

            fresh?(row) ? add(row, num, type) : append(row, num, type)
            row
          end

          private

          attr_reader :numtarget, :typetarget, :delim

          def fresh?(row)
            true unless row.keys.include?(numtarget)
          end

          def add(row, num, type)
            row[numtarget] = num
            row[typetarget] = type
            row
          end

          def append(row, num, type)
            row[numtarget] = [row[numtarget], num].join(delim)
            row[typetarget] = [row[typetarget], type].join(delim)
            row
          end
        end
      end
    end
  end
end
