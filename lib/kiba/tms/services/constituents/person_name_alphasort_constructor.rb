# frozen_string_literal: true

module Kiba
  module Tms
    module Services
      module Constituents
        # Creates an inverted direct order name from person name parts
        class PersonNameAlphasortConstructor
          def initialize
            @fields = %i[lastname firstname middlename suffix]
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(fields: fields)
          end

          def call(row)
            parts = getter.call(row)
            return nil if parts.empty?

            post_comma = [parts[:firstname], parts[:middlename]].compact.join(' ')
            joinable = post_comma.empty? ? nil : post_comma
            [parts[:lastname], joinable, parts[:suffix]].compact.join(', ')
          end

          private

          attr_reader :fields, :getter
        end
      end
    end
  end
end
