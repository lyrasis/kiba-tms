# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameCompile
        class SelectCanTypemismatchMainOrg
          # @private
          def process(row)
            return unless eligible?(row)

            row
          end

          private

          def main_org?(row)
            main = row[:conauthtype]
            return false if main.blank?

            true if main.start_with?("Organization")
          end

          def alt_unestablished?(row)
            altcon = row[:altnameconid]
            true if altcon.blank?
          end

          def eligible?(row)
            main_org?(row) && alt_person?(row) && alt_unestablished?(row)
          end

          def alt_person?(row)
            alt = row[:altauthtype]
            return false if alt.blank?

            true if alt.start_with?("Person")
          end
        end
      end
    end
  end
end
