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
        end

        def call
          return nil unless mod.used?

          value_getter.call
            .map{ |val| lookup_table_name(val) }
        end

        private

        attr_reader :mod, :value_getter, :lookup

        def lookup_table_name(val)
          result = lookup[val]
          return result if result

          warn("Unknown table ID: #{val}. Add mapping to Tms.table_lookup")
          "UNKNOWN TABLE #{val}"
        end
      end
    end
  end
end
