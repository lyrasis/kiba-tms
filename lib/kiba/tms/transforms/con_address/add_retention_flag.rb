# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConAddress
        class AddRetentionFlag
          def initialize
            @matches_field = :matches_constituent
            @target = :keeping
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: Tms::ConAddress.address_fields
            )
            @chks = if Tms::ConAddress.omit_inactive_address
              %i[no_match inactive data]
            else
              %i[no_match data]
            end
          end

          # @private
          def process(row)
            row[target] = "y"
            run_chks(chks, row)
            row.delete(matches_field)
            row
          end

          private

          attr_reader :matches_field, :target, :getter, :chks

          def no_match(row)
            val = row[matches_field]
            val.blank? ? "n - associated constituent not migrating" : "y"
          end

          def inactive(row)
            val = row[:active]
            return "n - inactive address" if val == "0"

            "y"
          end

          def data(row)
            vals = getter.call(row).values
            return "n - no address data in row" if vals.empty?

            "y"
          end

          def run_chks(chks, row)
            chks.each do |chk|
              result = send(chk, row)
              if result == "y"
                next
              else
                row[target] = result
                break
              end
            end
          end
        end
      end
    end
  end
end
