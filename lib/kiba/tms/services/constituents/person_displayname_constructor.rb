# frozen_string_literal: true

module Kiba
  module Tms
    module Services
      module Constituents
        # Creates a direct order name from person name parts
        class PersonDisplaynameConstructor
          include Kiba::Extend::Transforms::Helpers
          
          def initialize
          end

          def call(row)
            parts = field_values(row: row, fields: %i[lastname firstname middlename suffix])
            return nil if parts.empty?

            name = [parts[:firstname], parts[:middlename], parts[:lastname]].compact.join(' ')
            [name, parts[:suffix]].compact.join(', ')
          end
        end
      end
    end
  end
end
