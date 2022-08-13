# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameCompile
        class SelectCanTypematchEstablished
          # @private
          def process(row)
            return unless eligible?(row)
            
            row
          end
          
          private

          def eligible?(row)
            type_match?(row) && alt_name_established?(row)
          end

          def type_match?(row)
            row[:conauthtype] == row[:altauthtype]
          end

          def alt_name_established?(row)
            true unless row[:altconname].blank?
          end
        end
      end
    end
  end
end
