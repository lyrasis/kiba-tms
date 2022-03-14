# frozen_string_literal: true

module Kiba
  module Tms
    module Services
      module Constituents
        # Creates a direct order name from person name parts
        class PersonNameAlphasortConstructor
          include Kiba::Extend::Transforms::Helpers
          
          def initialize
          end

          def call(row)
            parts = field_values(row: row, fields: %i[lastname firstname middlename suffix])
            return nil if parts.empty?

            post_comma = [parts[:firstname], parts[:middlename]].compact.join(' ')
            joinable = post_comma.empty? ? nil : post_comma
            [parts[:lastname], joinable, parts[:suffix]].compact.join(', ')
          end
        end
      end
    end
  end
end
