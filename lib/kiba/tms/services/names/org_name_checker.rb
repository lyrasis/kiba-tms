# frozen_string_literal: true

module Kiba
  module Tms
    module Services
      module Names
        # Indicates whether value of field contains terms indicating organization-ness
        class OrgNameChecker
          def initialize(field:)
            @field = field
          end

          def call(row)
            val = row[field]
            return false if val.blank?

            true if patterns.any?{ |pattern| val.downcase.match?(pattern) }
          end

          private

          attr_reader :field

          def patterns
            [
              ' LLC',
              ' co$',
              ' co\.',
              ' dept$',
              ' inc$',
              '^\w+ & \w+$',
              'college',
              'company',
              'department',
              'dept\.',
              'foundation',
              'gallery',
              'inc\.',
              'library',
              'museum',
              'observatory',
              'publish',
              'service',
              'studio',
              'university'
            ].map{ |pattern| Regexp.new(pattern) }
          end
        end
      end
    end
  end
end
