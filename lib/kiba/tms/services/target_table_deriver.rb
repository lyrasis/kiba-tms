# frozen_string_literal: true

require 'dry/monads'

module Kiba
  module Tms
    module Services
      class TargetTableDeriver
        include Dry::Monads[:result]
        
        def self.call(...)
          self.new(...).call
        end
        
        def initialize(mod)
          @mod = mod
          @value_getter = Tms::Services::UniqueFieldValues.new(mod.table.supplied_data_path, :tableid)
          @lookup = Tms.table_lookup
          @tables = Tms::Table::List.call
        end

        def call
          return nil unless mod.used?

          value_getter.call
            .map{ |val| lookup_table_name(val) }
            .compact
            .select{ |table| tables.any?(table) }
        end

        private

        attr_reader :mod, :value_getter, :lookup, :tables

        def lookup_table_name(val)
          return nil if val.blank?
          return nil if val == '0'
          
          result = lookup[val]
          return result if result

          warn("Unknown table ID: `#{val}`. Add mapping to Tms.table_lookup")
          "UNKNOWN TABLE `#{val}`"
        end
      end
    end
  end
end
