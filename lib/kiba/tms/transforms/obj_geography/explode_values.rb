# frozen_string_literal: true

require 'set'

module Kiba
  module Tms
    module Transforms
      module ObjGeography
        class ExplodeValues
          include Kiba::Extend::Transforms::Helpers

          def initialize
            @fields = Tms::ObjGeography.content_fields
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: fields
            )
            @rows = Set[]
          end

          def process(row)
            getter.call(row)
              .each do |fieldname, value|
                rows << {fieldname: fieldname, value: value}
              end
            nil
          end

          def close
            rows.each{ |row| yield row }
          end

          private

          attr_reader :fields, :getter, :rows
        end
      end
    end
  end
end
