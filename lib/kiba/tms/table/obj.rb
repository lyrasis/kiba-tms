# frozen_string_literal: true

module Kiba
  module Tms
    # value object bundling table attributes, given table file
    module Table
      class Obj
        attr_reader :filename, :filekey, :included
        
        def initialize(filename)
          @filename = filename
          @filekey = Tms::Table::RegistryKeyCreator.call(filename)
          @included = Tms.excluded_tables.any?(filename) ? false : true
        end
      end
    end
  end
end
