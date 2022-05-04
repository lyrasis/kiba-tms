# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        class PrefixMergeTableDescription
          include Kiba::Extend::Transforms::Helpers

          def initialize(fields:)
            @fields = fields
          end
          
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
          attr_reader :fields
          
          def row_type(row)
            vals = field_values(row: row, fields: %i[email web])
            return vals.keys.first
          end
        end
      end
    end
  end
end
