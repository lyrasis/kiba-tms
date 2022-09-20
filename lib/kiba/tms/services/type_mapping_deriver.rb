# frozen_string_literal: true

require 'csv'
require 'dry/monads'
require 'dry/monads/do'

module Kiba
  module Tms
    module Services
      class TypeMappingDeriver
        include Dry::Monads[:result]
        include Dry::Monads::Do.for(:call)
        
        def self.call(...)
          self.new(...).call
        end
        
        def initialize(mod)
          @mod = mod
          return unless eligible?
          
          @value_getter = Tms::Services::UniqueTypeValuesUsed.new(mod)
          @id_field = mod.id_field
          @type_field = mod.type_field
          @no_val_xform = Tms::Transforms::DeleteNoValueTypes.new(field: type_field)
          @default_mapping = mod.mappings.empty? ? false : true
          @setting_name = "#{mod}.config.mappings"
        end

        def call
          return unless eligible?

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
          vals = vals_as_rows
          return Failure(nil) unless vals
          
          result = vals.map{ |row| no_val_xform.process(row) }
            .compact
            .map{ |row| row[type_field] }
        rescue StandardError => err
          Failure(setting_name, err)
        else
          default_mapping ? Success(result - mod.mappings.keys) : Success(result)
        end

        def eligible?
          mod.respond_to?(:mappable_type?) && mod.mappable_type?
        end

        def default_mapped(value)
          case mod.default_mapping_treatment
          when :self
            value
          when :downcase
            value.downcase
          when :todo
            'TODO: provide mapping'
          end
        end

        def mapping_hash(values)
          result = values.map{ |val| [val, default_mapped(val)] }.to_h
        rescue StandardError => err
          Failure(setting_name, err)
        else
          Success(result)
        end

        def used_val_ids
          vals = value_getter.call
          return nil unless vals
          
          vals.values
            .flatten
            .uniq
        end
        
        def vals_as_rows
          vals = vals_from_table
          return nil unless vals
          
          vals.map{ |val| {type_field => val} }
        end
        
        def vals_from_table
          path = mod.table_path
          used = used_val_ids
          return nil unless used
          
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
