# frozen_string_literal: true

require 'csv'
require 'dry/monads'

module Kiba
  module Tms
    module Data
      class Column
        include Dry::Monads[:result]

        # @param column [String] like "TableName.field_name"
        def initialize(column)
          parts = column.split('.')
          @mod = set_mod(parts[0])
          @table = mod.table
          @field = parts[1].to_sym
          @path = mod.table_path
          @status = Success() unless instance_variable_defined?(:@status)
        end

        def unique_values
          vals = []
          CSV.foreach(path, headers: true, header_converters: %i[downcase symbol]) do |row|
            val = row[field]
            vals << val unless vals.any?(val)
          end
        rescue StandardError => err
          Failure(err)
        else
          Success(vals)
        end

        def to_monad
          status.failure? ? status : Success(self)
        end

        private

        attr_reader :mod, :table, :path, :field, :status

        def set_mod(tablename)
          result = Tms.const_get(tablename)
        rescue StandardError => err
          @status = Failure(err)
          nil
        else
          result
        end
      end
    end
  end
end
