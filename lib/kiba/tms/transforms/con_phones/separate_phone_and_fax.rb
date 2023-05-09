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
            @fax_pattern = 'fax(| number| num\.?| no\.?| ?#)'
          end

          # @private
          def process(row)
            row[:phone] = nil
            row[:fax] = nil
            row[:faxtype] = nil

            number = row[:phonenumber]
            desc = row[desc_field]
            if desc.blank?
              treat_as_phone(number, row)
            # This keeps "Telephone/fax" numbers as phone numbers
            elsif /phone/i.match?(desc)
              treat_as_phone(number, row)
            elsif /^fax/i.match?(desc)
              treat_as_fax(number, row, desc)
            elsif / #{fax_pattern}$/i.match?(desc)
              treat_as_fax(number, row, desc)
            else
              treat_as_phone(number, row)
            end

            row.delete(:phonenumber)
            row
          end

          private

          attr_reader :desc_field, :fax_pattern

          def treat_as_phone(number, row)
            row[:phone] = number
          end

          def treat_as_fax(number, row, desc)
            row[:description] = if /^#{fax_pattern}$/i.match?(desc)
              nil
            else
              desc.gsub(/#{fax_pattern}/i, "")
                .strip
            end
            row[:fax] = number
            row[:faxtype] = row[:phonetype]
            row[:phonetype] = nil
          end
        end
      end
    end
  end
end
