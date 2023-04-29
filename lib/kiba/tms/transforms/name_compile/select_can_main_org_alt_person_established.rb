# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module NameCompile
        class SelectCanMainOrgAltPersonEstablished
          # @private
          def process(row)
            return unless eligible?(row)

            row
          end

          private

          def alt_type_eligible?(row)
            row[:altauthtype] == "Person"
          end

          def eligible?(row)
            main_type_eligible?(row) && alt_type_eligible?(row) && alt_name_established?(row)
          end

          def main_type_eligible?(row)
            row[:conauthtype] == "Organization"
          end

          def alt_name_established?(row)
            true unless row[:altconname].blank?
          end
        end
      end
    end
  end
end
