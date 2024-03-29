# frozen_string_literal: true

require "csv"
require "dry/monads"
require "dry/monads/do"

module Kiba
  module Tms
    module Data
      class Column
        include Dry::Monads[:result]
        include Dry::Monads::Do.for(:unique_values, :value_counts)

        # @param mod [Module, String]
        # @param field [Symbol, String]
        def initialize(mod:, field:, table_getter: Tms::Data::CsvEnum)
          @mod = set_mod(mod)
          @field = field.to_sym
          @table_getter = table_getter.call(mod: @mod)
          @status = Success() unless instance_variable_defined?(:@status)
        end

        def unique_values
          return status unless status.success?

          rows = yield table_getter
          vals = yield rows_to_vals(rows)

          Success(vals)
        end

        # @return [Hash] key: field value, value: number of times value
        #   occurs in table
        def value_counts
          return status unless status.success?

          rows = yield table_getter
          counts = yield count_vals(rows)

          Success(counts)
        end

        def to_monad
          status.failure? ? status : Success(self)
        end

        private

        attr_reader :mod, :field, :table_getter, :status

        def count_vals(rows)
          result = {}
          rows.each do |row|
            next unless row.key?(field)

            val = row[field]
            result[val] = 0 unless result.key?(val)
            result[val] += 1
          end
        rescue => err
          Failure(err)
        else
          Success(result)
        end

        def rows_to_vals(rows)
          result = rows.map { |row| row.key?(field) ? row[field] : nil }
            .compact
            .sort
            .uniq
        rescue => err
          Failure(err)
        else
          Success(result)
        end

        def set_mod(mod)
          result = if mod.is_a?(Module) || mod.is_a?(Symbol)
            mod
          else
            Tms.const_get(mod)
          end
        rescue => err
          @status = Failure(err)
          nil
        else
          return result if result.is_a?(Symbol)

          @status = Failure(:table_not_used) unless result.used?
          result
        end
      end
    end
  end
end
