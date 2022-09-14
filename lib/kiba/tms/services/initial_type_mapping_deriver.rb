# frozen_string_literal: true

require 'csv'
require 'dry/monads'
require 'dry/monads/do'

module Kiba
  module Tms
    module Services
      class InitialTypeMappingDeriver
        include Dry::Monads[:result]
        include Dry::Monads::Do.for(:call)
        
        def self.call(...)
          self.new(...).call
        end
        
        def initialize(mod)
          @mod = mod
          @value_getter = Tms::Services::UniqueTypeValuesUsed.new(mod)
          @id_field = mod.id_field
          @type_field = mod.type_field
          @no_val_xform = Tms::Transforms::DeleteNoValueTypes.new(field: type_field)
          @default_mapping = mod.mappings.empty? ? false : true
          @setting_name = "#{mod}.config.mappings"
        end

        def call
          clean = yield(cleaned)
          hash = yield(mapping_hash(clean))
          return nil if clean.empty?

          if default_mapping
            Success("#{setting_name} = #{mod.mappings.merge(hash)}")
          else
            Success("#{setting_name} = #{hash}")
          end
        end

        private

        attr_reader :mod, :value_getter, :id_field, :type_field, :no_val_xform, :default_mapping, :setting_name

        def cleaned
          result = vals_as_rows.map{ |row| no_val_xform.process(row) }
            .compact
            .map{ |row| row[type_field] }
        rescue StandardError => err
          Failure(setting_name, err)
        else
          default_mapping ? Success(result - mod.mappings.keys) : Success(result)
        end

        def mapping_hash(values)
          result = values.map{ |val| [val, val.downcase] }.to_h
        rescue StandardError => err
          Failure(setting_name, err)
        else
          Success(result)
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
