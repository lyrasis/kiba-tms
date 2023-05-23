# frozen_string_literal: true

require 'set'

module Kiba
  module Tms
    module Transforms
      module ObjGeography
        # When a whole field value is wrapped in parentheses, the outer
        #   parentheses are removed. "(This)" becomes "This", while
        #   "New York (NY)" would be left the same.
        class RemoveFullParentheticals
          include Kiba::Extend::Transforms::Helpers

          def initialize(fields: Tms::ObjGeography.content_fields)
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: fields
            )
          end

          def process(row)
            to_fix = get_parentheticals(row)
            return row if to_fix.empty?

            remove_parentheticals(row, to_fix)
            row
          end

          private

          attr_reader :getter

          def get_parentheticals(row)
            getter.call(row)
              .select{ |_field, value| value.match(/^\(.*\)$/) }
          end

          def remove_parentheticals(row, to_fix)
            to_fix.each do |field, value|
              row[field] = value.sub(/^\((.*)\)$/, '\1')
            end
          end
        end
      end
    end
  end
end
