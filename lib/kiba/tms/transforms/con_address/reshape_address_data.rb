# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConAddress
        class ReshapeAddressData
          include Kiba::Extend::Transforms::Helpers
          
          def initialize
            @fields1 = Tms::Constituents.addressplace1_fields
            @fields2 = Tms::Constituents.addressplace2_fields
            @delim1 = Tms::Constituents.addressplace1_delim
            @delim2 = Tms::Constituents.addressplace2_delim
          end

          # @private
          def process(row)
            ap1 = field_values(row: row, fields: fields1).values
            ap2 = field_values(row: row, fields: fields2).values

            ap1 << ap2.shift if ap1.empty? && !ap2.empty?
            row[:addressplace1] = ap1.join(delim1)
            row[:addressplace2] = ap2.join(delim2)
            [fields1, fields2].flatten.each{ |field| row.delete(field) }
            row
          end
          
          private

          attr_reader :fields1, :fields2, :delim1, :delim2

        end
      end
    end
  end
end
