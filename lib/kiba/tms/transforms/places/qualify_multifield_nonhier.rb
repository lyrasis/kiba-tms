# frozen_string_literal: true

require "set"

module Kiba
  module Tms
    module Transforms
      module Places
        class QualifyMultifieldNonhier
          def initialize
            @chk = {}
            @rows = []
          end

          def process(row)
            val = row[:norm]
            vals = val.split("///")
            term = vals[0]
            src = vals[1]
            populate_chk(term, src)
            row[:norm] = term
            row[:src] = src
            rows << row
            nil
          end

          def close
            rows.each do |row|
              multifield?(row) ? qualify(row) : unqualify(row)
              yield row
            end
          end

          private

          attr_reader :chk, :rows

          def populate_chk(term, src)
            if chk.key?(term)
              chk[term].add(src)
            else
              chk[term] = Set[src]
            end
          end

          def multifield?(row)
            chk[row[:norm]].length > 1
          end

          def unqualify(row)
            row.delete(:src)
          end

          def qualify(row)
            term = row[:norm]
            src = row[:src]
            row.delete(:src)
            row[:norm] = "#{term} (#{src})"
          end
        end
      end
    end
  end
end
