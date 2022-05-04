# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConEmail
        class AddRetentionFlag
          include Kiba::Extend::Transforms::Helpers
          
          def initialize
            @matches_field = :matches_constituent
            @target = :keeping
          end

          # @private
          def process(row)
            chks = %i[no_match]
            chks.each do |chk|
              result = send(chk, row)
              if result == 'y'
                next
              else
                row[target] = result
                return row
              end
            end
            row.delete(matches_field)
            row[target] = 'y'
            row
          end
          
          private

          attr_reader :matches_field, :target

          def no_match(row)
            val = row[matches_field]
            val.blank? ? 'n - associated constituent not migrating' : 'y'
          end
        end
      end
    end
  end
end
