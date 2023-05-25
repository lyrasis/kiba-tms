# frozen_string_literal: true

require 'set'

module Kiba
  module Tms
    module Transforms
      module ObjGeography
        class ExplodeValues
          include Kiba::Extend::Transforms::Helpers

          def initialize(referencefield:)
            @referencefield = referencefield
            @fields = Tms::ObjGeography.content_fields
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: fields
            )
            @rows = {}
          end

          def process(row)
            getter.call(row)
              .each do |fieldname, value|
                rows[{fieldname: fieldname, value: value}] = row[referencefield]
              end
            nil
          end

          def close
            rows.each do |base, combined|
              base[referencefield] = combined
              yield base
            end
          end

          private

          attr_reader :referencefield, :fields, :getter, :rows
        end
      end
    end
  end
end
