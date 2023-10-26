# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameTypeCleanup
        class MergeCorrectData
          def initialize(
            lookup:,
            delim: Tms.delim,
            nametarget: :correctname,
            typetarget: :correctauthoritytype,
            keycolumn: :constituentid
          )
            @lookup = lookup
            @delim = delim
            @targets = {
              name: nametarget,
              type: typetarget
            }
            @keycolumn = keycolumn
          end

          def process(row)
            targets.values.each { |field| row[field] = nil }
            correct_values(row).each do |valtype, val|
              row[targets[valtype]] = val
            end
            row
          end

          private

          attr_reader :lookup, :delim, :targets, :keycolumn,
            :merger

          def correct_values(row)
            lookuprows = lookup[row[keycolumn]]
            rowlen = lookuprows&.length
            return {} unless rowlen

            result = if rowlen == 1
              {
                name: lookuprows[0][:correctname],
                type: lookuprows[0][:correctauthoritytype]
              }
            elsif rowlen > 1
              multi_row_correct_values(lookuprows)
            else
              {}
            end
            result.reject { |key, val| val.blank? }
          end

          def multi_row_correct_values(lookuprows)
            {
              name: last_correct_value(lookuprows, :correctname),
              type: last_correct_value(lookuprows, :correctauthoritytype)
            }
          end

          def last_correct_value(lookuprows, field)
            lookuprows.map { |r| r[field] }
              .reject { |val| val.blank? }
              .last
          end
        end
      end
    end
  end
end
