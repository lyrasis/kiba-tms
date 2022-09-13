# frozen_string_literal: true

require 'csv'

module Kiba
  module Tms
    module Services
      # Returns :success if the given field is empty. Returns :failure if not.
      class EmptyFieldChecker
        def self.call(...)
          self.new(...).call
        end
        
        def initialize(table, mod, field)
          @table = table
          @mod = mod
          @field = field[0]
          @emptyvals = [field[1], nil, ''].flatten.uniq

          @path = table.supplied_data_path
          @index = set_index
        end

        def call
          return nil unless path
          return nil unless index
          
          check_rows
        end

        private

        attr_reader :table, :mod, :field, :emptyvals, :path, :index

        def check_rows
          CSV.foreach(path, headers: true) do |row|
            return :failure unless emptyvals.any?(row[index])
          end
          :success
        end

        def set_index
          idx = mod.send(:all_fields).find_index(field)
          warn("#{self.class.name}: Unknown field `#{field}` in #{table.tablename} table") unless idx
          idx
        end
      end
    end
  end
end
