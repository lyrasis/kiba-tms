# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        class PrefixMergeTableDescription
          def initialize(fields:)
            @fields = fields
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: fields
            )
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

          attr_reader :fields, :getter

          def row_type(row)
            vals = getter.call(row)
            return vals.keys.first
          end
        end
      end
    end
  end
end
