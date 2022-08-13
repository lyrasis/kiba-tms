# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameCompile
        class SelectCanTypematch
          # @private
          def process(row)
            return unless eligible?(row)
            
            row
          end
          
          private

          def eligible?(row)
            type_match?(row) && unestablished_alt_name?(row)
          end

          def type_match?(row)
            row[:conauthtype] == row[:altauthtype]
          end

          def unestablished_alt_name?(row)
            true if row[:altconname].blank?
          end
        end
      end
    end
  end
end
