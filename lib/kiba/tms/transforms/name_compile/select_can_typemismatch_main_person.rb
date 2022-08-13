# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameCompile
        class SelectCanTypemismatchMainPerson
          # @private
          def process(row)
            return unless eligible?(row)
            
            row
          end
          
          private

          def alt_org?(row)
            alt = row[:altauthtype]
            return false if alt.blank?

            true if alt == 'Organization'
          end

          def alt_unestablished?(row)
            altcon = row[:altnameconid]
            true if altcon.blank?
          end

          def eligible?(row)
            main_person?(row) && alt_org?(row) && alt_unestablished?(row)
          end

          def main_person?(row)
            main = row[:conauthtype]
            return false if main.blank?
            
            true if main == 'Person'
          end
        end
      end
    end
  end
end
