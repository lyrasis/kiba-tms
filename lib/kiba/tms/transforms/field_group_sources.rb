# frozen_string_literal: true

module Kiba
  module Tms
    module Transforms
      class FieldGroupSources
        def initialize(grouped_fields:, prefix:, value_map: {},
          constant_map: {}, delim: Tms.delim, nullval: Tms.nullvalue)
          @grouped_fields = grouped_fields.map do |key|
            "#{prefix}_#{key}".to_sym
          end
          @prefix = prefix
          @value_map = value_map.transform_keys do |key|
            "#{prefix}_#{key}".to_sym
          end
          @constant_map = constant_map.transform_keys do |key|
            "#{prefix}_#{key}".to_sym
          end
          @delim = delim
          @nullval = nullval
        end

        def process(row)
          mapped = grouped_fields.map { |field| [field, get_value(field, row)] }
            .to_h
          row.merge(mapped)
        end

        private

        attr_reader :grouped_fields, :prefix, :value_map, :constant_map, :delim,
          :nullval

        def get_value(field, row)
          if value_map.key?(field)
            srcfield = value_map[field]
            val = row[srcfield]
            val.blank? ? nullval : val
          elsif constant_map.key?(field)
            constant_map[field]
          else
            nullval
          end
        end
      end
    end
  end
end
