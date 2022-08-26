# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameCompile
        class SelectCanTypematch
          def initialize
            @normalizer = Tms::Services::Constituents::ContypeNormalizer.new
          end
          
          def process(row)
            return unless eligible?(row)
            
            row
          end
          
          private

          attr_reader :normalizer
          
          def eligible?(row)
            type_match?(row) && unestablished_alt_name?(row)
          end

          def type_match?(row)
            normalizer.call(row[:conauthtype]) == normalizer.call(row[:altauthtype])
          end

          def unestablished_alt_name?(row)
            true if row[:altconname].blank?
          end
        end
      end
    end
  end
end
