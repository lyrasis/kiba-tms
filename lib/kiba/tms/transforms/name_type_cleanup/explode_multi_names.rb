# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameTypeCleanup
        class ExplodeMultiNames
          def initialize(
            delim: Tms.delim,
            target: Tms::Constituents.preferred_name_field
          )
            @delim = delim
            @target = target
            @rows = []
          end

          def process(row)
            if eligible?(row)
              explode(row)
            else
              rows << row
            end
            nil
          end

          def close
            rows.each { |row| yield row }
          end

          private

          attr_reader :delim, :target, :merger, :rows

          def eligible?(row)
            val = row[:correctname]
            return false if val.blank?

            val.include?(delim)
          end

          def explode(row)
            corrnames = row[:correctname].split(delim)
            corrtype = row[:correctauthoritytype]
            corrtypes = corrtype.blank? ? [] : corrtype.split(delim)
            row[:correctname] = nil
            row[:correctauthoritytype] = nil
            conid = row[:constituentid]

            corrnames.each_with_index do |corrname, idx|
              newrow = row.dup
              newrow[target] = corrname
              newrow[:correctauthoritytype] = corrtypes[idx]
              newrow[:constituentid] = "#{conid}_exploded#{idx}"
              rows << newrow
            end

            nil
          end
        end
      end
    end
  end
end
