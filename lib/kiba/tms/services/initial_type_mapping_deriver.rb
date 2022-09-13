# frozen_string_literal: true

require 'csv'

module Kiba
  module Tms
    module Services
      class InitialTypeMappingDeriver
        def self.call(...)
          self.new(...).call
        end
        
        def initialize(mod)
          @mod = mod
          @value_getter = Tms::Services::UniqueTypeValuesUsed.new(mod)
          @id_field = mod.id_field
          @type_field = mod.type_field
          @no_val_xform = Tms::Transforms::DeleteNoValueTypes.new(field: type_field)
        end

        def call
          "#{mod}.config.mapping = #{mapping_hash}"
        end

        private

        attr_reader :mod, :value_getter, :id_field, :type_field, :no_val_xform

        def cleaned
          vals_as_rows.map{ |row| no_val_xform.process(row) }
            .compact
            .map{ |row| row[type_field] }
        end

        def mapping_hash
          cleaned.map{ |val| [val, val.downcase] }.to_h
        end

        def used_val_ids
          value_getter.call
            .values
            .flatten
            .uniq
        end
        
        def vals_as_rows
          vals_from_table.map{ |val| {type_field => val} }
        end
        
        def vals_from_table
          path = mod.table.supplied_data_path
          used = used_val_ids
          vals = []
          CSV.foreach(path, headers: true, header_converters: %i[downcase symbol]) do |row|
            next unless used.any?(row[id_field])

            vals << row[type_field]
          end
          vals
        end
      end
    end
  end
end
