# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConPhones
        # for use on tables to merge with constituents on constituentid
        class SeparatePhoneAndFax
          include Kiba::Extend::Transforms::Helpers
          
          def initialize
            @desc_field = :description
          end

          # @private
          def process(row)
            row[:phone] = nil
            row[:fax] = nil
            
            number = row[:phonenumber]
            desc = row[desc_field]
            if desc.blank?
              row[:phone] = number
            elsif desc =~ /^fax$/i
              row[:description] = nil
              row[:fax] = number
            else
              row[:phone] = number
            end
            
            row.delete(:phonenumber)
            row
          end
          
          private

          attr_reader :desc_field
        end
      end
    end
  end
end
