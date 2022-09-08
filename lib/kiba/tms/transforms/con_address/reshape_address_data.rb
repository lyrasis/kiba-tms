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
            @getter1 = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: fields1
            )
            @getter2 = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: fields2
            )
            @delim1 = Tms::Constituents.addressplace1_delim
            @delim2 = Tms::Constituents.addressplace2_delim
          end

          # @private
          def process(row)
            %i[addressplace1 addressplace2].each{ |field| row[field] = nil }
            
            ap1 = getter1.call(row).values
            ap2 = getter2.call(row).values
            return row if ap1.empty? && ap2.empty?
            
            ap1 << ap2.shift if ap1.empty? && !ap2.empty?
            row[:addressplace1] = ap1.join(delim1)
            row[:addressplace2] = ap2.join(delim2)
            [fields1, fields2].flatten.each{ |field| row.delete(field) }
            row
          end
          
          private

          attr_reader :fields1, :fields2, :getter1, :getter2, :delim1, :delim2

        end
      end
    end
  end
end
