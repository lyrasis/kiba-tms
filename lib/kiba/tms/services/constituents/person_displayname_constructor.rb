# frozen_string_literal: true

module Kiba
  module Tms
    module Services
      module Constituents
        # Creates a direct order name from person name parts
        class PersonDisplaynameConstructor
          def initialize
            @value_getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: %i[lastname firstname middlename suffix]
              )
          end

          def call(row)
            parts = value_getter.call(row)
            return nil if parts.empty?

            name = [parts[:firstname], parts[:middlename], parts[:lastname]].compact.join(' ')
            [name, parts[:suffix]].compact.join(', ')
          end

          private

          attr_reader :value_getter
        end
      end
    end
  end
end
