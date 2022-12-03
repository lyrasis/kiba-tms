# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameTypeCleanup
        class ExplodeMultiNames
          def initialize(delim: Tms.delim,
                         target: Tms::Constituents.preferred_name_field,
                         lookup:,
                         keycolumn: :constituentid
                         )
            @delim = delim
            @target = target
            @merger = Merge::MultiRowLookup.new(
              lookup: lookup,
              keycolumn: keycolumn,
              fieldmap: {
                correctname: :correctname,
                correctauthoritytype: :correctauthoritytype
              }
            )
            @rows = []
          end

          def process(row)
            merger.process(row)

            unless eligible?(row)
              rows << row
              return nil
            end

            corrnames = row[:correctname].split(delim)
            corrtype = row[:correctauthoritytype]
            corrtypes = corrtype.blank? ? [] : corrtype.split(delim)
            row[:correctname] = nil
            row[:correctauthoritytype] = nil

            corrnames.each_with_index do |corrname, idx|
              newrow = row.dup
              newrow[target] = corrname
              newrow[:correctauthoritytype] = corrtypes[idx]
              rows << newrow
            end

            nil
          end

          def close
            rows.each{ |row| yield row }
          end

          private

          attr_reader :delim, :target, :merger, :rows

          def eligible?(row)
            val = row[:correctname]
            return false if val.blank?

            val.include?(delim)
          end
        end
      end
    end
  end
end
