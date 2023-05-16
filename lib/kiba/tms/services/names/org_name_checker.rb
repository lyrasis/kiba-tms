# frozen_string_literal: true

module Kiba
  module Tms
    module Services
      module Names
        # Indicates (true/false) whether value of field matches any pattern
        #   strongly suggesting organization-ness
        class OrgNameChecker
          # @param [Symbol] fieldname containing value to check
          def initialize(field:)
            @field = field
            @checker = Kiba::Extend::Transforms::Helpers::OrgNameChecker.new(
              family_is_org: true
            )
          end

          def call(row)
            val = row[field]
            return false if val.blank?

            checker.call(val)
          end

          private

          attr_reader :checker, :field
        end
      end
    end
  end
end
