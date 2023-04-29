# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        # for use on tables to merge with constituents on constituentid
        class AddRetentionFlag
          def initialize(field: :matches_constituent)
            @matches_field = field
            @target = :keeping
          end

          # @private
          def process(row)
            val = row[matches_field]
            result = val.blank? ? "n - associated constituent not migrating" : "y"
            row.delete(matches_field)
            row[target] = result
            row
          end

          private

          attr_reader :matches_field, :target
        end
      end
    end
  end
end
