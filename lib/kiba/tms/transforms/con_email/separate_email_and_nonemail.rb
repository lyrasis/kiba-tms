# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ConEmail
        class SeparateEmailAndNonemail
          include Kiba::Extend::Transforms::Helpers

          # @private
          def process(row)
            row[:email] = nil
            row[:web] = nil
            val = row[:emailaddress]
            return row if val.blank?

            val['@'] ? row[:email] = val : row[:web] = val
            row.delete(:emailaddress)
            row
          end
        end
      end
    end
  end
end
