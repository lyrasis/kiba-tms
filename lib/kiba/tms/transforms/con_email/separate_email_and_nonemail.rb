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
            row[:webtype] = nil
            val = row[:emailaddress]
            return row if val.blank?

            val["@"] ? treat_as_email(val, row) : treat_as_web(val, row)
            row.delete(:emailaddress)
            row
          end

          private

          def treat_as_email(val, row)
            row[:email] = val
          end

          def treat_as_web(val, row)
            row[:web] = val
            row[:webtype] = row[:emailtype]
            row[:emailtype] = nil
          end
        end
      end
    end
  end
end
