# frozen_string_literal: true

require 'csv'

module Kiba
  module Tms
    module Services
      module Relationships
        # returns a Hash of counts of relationships defined per known/included table
        class DefinedRelGetter
          def self.call(...)
            self.new(...).call
          end
          
          def initialize
            @mod = Tms::Relationships
            @path = mod.table.supplied_data_path
            @acc = {}
            @lookup = Tms.table_lookup
            @tables = Tms::Table::List.call
          end

          def call
            return nil unless mod.used?
            return nil unless path

            get_values
            acc.transform_keys{ |key| lookup.fetch(key, key) }
              .reject{ |key, _ct| key.match(/^\d+$/) }
              .select{ |key, _ct| tables.any?(key) }
          end

          private

          attr_reader :mod, :path, :acc, :lookup, :tables
          
          def get_values
            CSV.foreach(path, headers: true, header_converters: %i[downcase symbol]) do |row|
              table = row[:tableid]
              acc[table] = 0 unless acc.key?(table)
              acc[table] += 1
            end
          end
        end
      end
    end
  end
end
