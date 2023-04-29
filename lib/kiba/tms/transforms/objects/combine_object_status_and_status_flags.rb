# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Objects
        class CombineObjectStatusAndStatusFlags
          def initialize
            @fields = %i[objectstatus status_flag_inventorystatus]
            @target = :inventorystatus
          end
          
          def process(row)
            row[target] = nil
            values = fields.map{ |field| row[field] }
              .reject{ |val| val.blank? }
              .map{ |str| str.split(Tms.delim) }
              .flatten
              .uniq
            combine(values, row)
            row
          end

          private

          attr_reader :fields, :target

          def combine(values, row)
            while fixable?(values)
              fix(values)
            end
            row[target] = values.sort.join(Tms.delim)
            fields.each{ |field| row.delete(field) }
          end

          def fix(values)
            if values.any?("unknown")
              values.delete("unknown")
              return values
            end

            if values.any?("potential return") && values.any?("returned")
              values.delete("potential return")
              return values
            end

          end
          
          def fixable?(values)
            return false if values.empty?
            return false if values.length == 1
            return true if values.any?("unknown")
            return true if values.any?("potential return") && values.any?("returned")
          end
        end
      end
    end
  end
end
