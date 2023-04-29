# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameCompile
        class SelectCanNoAltnametype
          # @private
          def process(row)
            return unless eligible?(row)

            row
          end

          private

          def no_altnametype?(row)
            type = row[:altauthtype]
            true if type.blank?
          end

          def alt_unestablished?(row)
            altcon = row[:altnameconid]
            true if altcon.blank?
          end

          def eligible?(row)
            no_altnametype?(row) && alt_unestablished?(row)
          end
        end
      end
    end
  end
end
