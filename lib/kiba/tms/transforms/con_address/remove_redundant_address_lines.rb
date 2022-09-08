# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConAddress
        class RemoveRedundantAddressLines
          
          def initialize
            @names = %i[displayname1 displayname2]
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(fields: %i[alphasort displayname])
          end

          # @private
          def process(row)
            chk = getter.call(row).values
            names.each{ |name| remove_redundant(row, name, chk) }
            
            row
          end
          
          private

          attr_reader :names, :getter

          def remove_redundant(row, name, chk)
            return unless row.key?(name)
            
            val = row.fetch(name, nil)
            return if val.blank?
            row[name] = nil if chk.any?(val)
          end
        end
      end
    end
  end
end
