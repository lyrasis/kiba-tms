# frozen_string_literal: true

require "csv"

module Kiba
  module Tms
    module Services
      # Returns :success if the given field is empty. Returns :failure if not.
      class EmptyFieldChecker
        def self.call(...)
          self.new(...).call
        end

        def initialize(mod:, field:, criteria:)
          @mod = mod
          @table = mod.table
          @field = field
          @criteria = criteria
          @emptyvals = [criteria, nil, ""].flatten.uniq

          @path = mod.table_path
          @index = set_index
        end

        def call
          return nil unless path
          return nil unless index

          check_rows
        end

        private

        attr_reader :table, :mod, :field, :criteria, :emptyvals, :path, :index

        def check_rows
          CSV.foreach(path, headers: true) do |row|
            return nil unless emptyvals.any?(row[index])
          end
          {field: field, criteria: criteria}
        end

        def set_index
          idx = mod.send(:all_fields).find_index(field)
          unless idx
            msg = "Unknown field `#{field}` in #{table.tablename} table"
            warn("#{self.class.name}: #{msg}")
          end
          idx
        end
      end
    end
  end
end
