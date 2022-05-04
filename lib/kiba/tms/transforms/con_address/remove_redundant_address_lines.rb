# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConAddress
        class RemoveRedundantAddressLines
          include Kiba::Extend::Transforms::Helpers
          
          def initialize
            @names = %i[displayname1 displayname2]
            @constnames = %i[alphasort displayname]
          end

          # @private
          def process(row)
            chk = field_values(row: row, fields: constnames).values
            names.each{ |name| remove_redundant(row, name, chk) }
            
            row
          end
          
          private

          attr_reader :names, :constnames

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
