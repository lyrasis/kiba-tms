# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      module ObjLocations
        class AddFulllocid
          include Kiba::Extend::Transforms::Helpers
          
          def initialize
            @target = :fulllocid
            @fields = Tms.locations.fulllocid_fields
            @placeholder = 'nil'
            @delim = Tms.delim
          end

          def process(row)
            fields.each{ |field| populate_temp(row, field) }
            row[target] = concat_id(row)
            temp_fields.each{ |field| row.delete(field) }
            row
          end

          private

          attr_reader :target, :fields, :placeholder, :delim

          def concat_id(row)
            field_values(row: row, fields: temp_fields).values.join(delim)
          end
          
          def populate_temp(row, field)
            val = row.fetch(field, placeholder)
            val.empty? ? row[temp(field)] = placeholder : row[temp(field)] = val
          end
          
          def temp(field)
            "#{field}_tmp".to_sym
          end
          
          def temp_fields
            fields.map{ |field| temp(field) }
          end
        end
      end
    end
  end
end
