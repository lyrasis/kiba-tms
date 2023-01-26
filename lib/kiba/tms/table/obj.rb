# frozen_string_literal: true

module Kiba
  module Tms
    # Value object bundling table attributes, given table file. Note that, since
    #   every job produces a table, a table can be derived from a job key
    module Table
      class Obj
        attr_reader :tablename, :filename, :filekey, :included, :type

        def initialize(tablename)
          @tablename = tablename
          if tablename.is_a?(Symbol)
            set_up_symbol_tablename
          else
            set_up_string_tablename
          end
        end

        def prepped_data_path
          return nil unless included

          Tms::Table::Prepped::RegistryHashCreator.call(self)[:path]
        end

        def supplied_data_path
          return nil unless included

          Tms::Table::Supplied::RegistryHashCreator.call(self)[:path]
        end

        def used?
          included
        end

        private

        attr_reader :reg_hash

        def set_up_string_tablename
          @filename = "#{tablename}.csv"
          @filekey = Tms::Table::RegistryKeyCreator.call(tablename)
          @included = Tms::Table::List.call.any?(tablename)
          @type = :tms
        end

        def set_up_symbol_tablename
          @filekey = tablename
          @type = :derived
          if Tms.registry.key?(tablename)
            @filename = Tms.registry.resolve(tablename).path.to_s
            @included = true
          else
            @filename = nil
            @included = false
          end
        end
      end
    end
  end
end
