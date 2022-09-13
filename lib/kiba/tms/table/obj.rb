# frozen_string_literal: true

module Kiba
  module Tms
    # value object bundling table attributes, given table file
    module Table
      class Obj
        attr_reader :tablename, :filename, :filekey, :included
        
        def initialize(tablename)
          @tablename = tablename
          @filename = "#{tablename}.csv"
          @filekey = Tms::Table::RegistryKeyCreator.call(tablename)
          @included = Tms::Table::List.call.any?(tablename)
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
      end
    end
  end
end
