# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module Constituents
        class ExtractPersonFromNameParts
          def initialize(target:)
            @target = target
            @builder = Tms::Constituents.preferred_name_field
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: %i[lastname firstname middlename suffix]
            )
          end

          def process(row)
            row[target] = nil
            @parts = getter.call(row)
            return row if parts.empty?

            row[target] = send(builder)
            row
          end

          private

          attr_reader :target, :builder, :getter, :parts

          def alphasort
            post_comma = [parts[:firstname],
              parts[:middlename]].compact.join(" ")
            joinable = post_comma.empty? ? nil : post_comma
            [parts[:lastname], joinable, parts[:suffix]].compact.join(", ")
          end

          def displayname
            name = [parts[:firstname], parts[:middlename],
              parts[:lastname]].compact.join(" ")
            [name, parts[:suffix]].compact.join(", ")
          end
        end
      end
    end
  end
end
