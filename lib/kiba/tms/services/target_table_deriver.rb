# frozen_string_literal: true

require 'dry/monads'
require 'dry/monads/do'

module Kiba
  module Tms
    module Services
      class TargetTableDeriver
        include Dry::Monads[:result]
        include Dry::Monads::Do.for(:call)

        def self.call(...)
          self.new(...).call
        end

        def initialize(mod:, table_field: :tableid, col: Tms::Data::Column)
          @mod = mod
          @table_field = table_field
          @col = col
          @lookup = Tms.table_lookup
          @nontables = Tms.excluded_tables
        end

        def call
          return Failure(:table_not_used) unless mod.used?

          column = yield col.new(mod: mod, field: table_field)
          vals = yield column.unique_values
          named = yield map_table_names(vals)
          clean = yield used_tables(named)

          Success(clean)
        end

        private

        attr_reader :mod, :table_field, :col, :lookup, :nontables

        def map_table_names(vals)
          result = vals.map{ |val| lookup_table_name(val) }
        rescue StandardError => err
          Failure(err)
        else
          Success(result)
        end

        def lookup_table_name(val)
          return nil if val.blank?
          return nil if val == '0'

          result = lookup[val]
          return result if result

          warn("Unknown table ID: `#{val}`. Add mapping to Tms.table_lookup")
          "UNKNOWN TABLE `#{val}`"
        end

        def used_tables(tables)
          result = tables.reject{ |table| nontables.any?(table) }
        rescue StandardError => err
          Failure(err)
        else
          Success(result)
        end
      end
    end
  end
end
