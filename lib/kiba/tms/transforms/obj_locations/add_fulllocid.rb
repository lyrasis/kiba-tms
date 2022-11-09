# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ObjLocations
        class AddFulllocid
          include Kiba::Extend::Transforms::Helpers

          def initialize
            @target = :fulllocid
            @fields = Tms::ObjLocations.fulllocid_fields
            @temp_fields = fields.map{ |field| temp(field) }
            @placeholder = 'nil'
            @delim = Tms.delim
            @getter = Kiba::Extend::Transforms::Helpers::FieldValueGetter.new(
              fields: temp_fields
            )
          end

          def process(row)
            fields.each{ |field| populate_temp(row, field) }
            row[target] = concat_id(row)
            temp_fields.each{ |field| row.delete(field) }
            row
          end

          private

          attr_reader :target, :fields, :temp_fields, :placeholder, :delim,
            :getter

          def concat_id(row)
            getter.call(row).values.join(delim)
          end

          def populate_temp(row, field)
            val = row.fetch(field, placeholder)
            val.empty? ? row[temp(field)] = placeholder : row[temp(field)] = val
          end

          def temp(field)
            "#{field}_tmp".to_sym
          end
        end
      end
    end
  end
end
