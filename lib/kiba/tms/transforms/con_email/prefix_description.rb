# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConEmail
        class PrefixDescription
          include Kiba::Extend::Transforms::Helpers
          
          # @private
          def process(row)
            desc = row[:description]
            return row if desc.blank?

            type = row_type(row)
            return row if type.blank?

            val = row[type]
            label = "#{type.capitalize} note (#{val}): "
            row[:description] = "#{label}#{desc}"
            row
          end
          
          private

          def row_type(row)
            vals = field_values(row: row, fields: %i[email web])
            return :email if vals.key?(:email)
            return :web if vals.key?(:web)
          end
        end
      end
    end
  end
end
