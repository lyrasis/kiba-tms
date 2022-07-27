# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConAddress
        class AddRetentionFlag
          include Kiba::Extend::Transforms::Helpers
          
          def initialize
            @matches_field = :matches_constituent
            @addr_fields = Tms::Constituents.address_fields
            @omit_inactive = Tms::Constituents.omit_inactive_address
            @target = :keeping
          end

          # @private
          def process(row)
            chks = omit_inactive ? %i[no_match inactive data] : %i[no_match data] 
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

          attr_reader :matches_field, :addr_fields, :omit_inactive, :target

          def no_match(row)
            val = row[matches_field]
            val.blank? ? 'n - associated constituent not migrating' : 'y'
          end

          def inactive(row)
            val = row[:active]
            return 'n - inactive address' if val == '0'

            'y'
          end

          def data(row)
            vals = field_values(row: row, fields: addr_fields).values
            return 'n - no address data in row' if vals.empty?

            'y'
          end
        end
      end
    end
  end
end
