# frozen_string_literal: true

require 'csv'
require 'dry/monads'
require 'dry/monads/do'

module Kiba
  module Tms
    module Data
      class Column
        include Dry::Monads[:result]
        include Dry::Monads::Do.for(:unique_values)

        # @param mod [Module, String]
        # @param field [Symbol, String]
        def initialize(mod:, field:, table_getter: Tms::Data::CsvEnum)
          @mod = set_mod(mod)
          @field = field.to_sym
          @table_getter = table_getter
          @status = Success() unless instance_variable_defined?(:@status)
        end

        def unique_values
          return status unless status.success?

          rows = yield table_getter.call(mod)
          vals = yield rows_to_vals(rows)

          Success(vals)
        end

        def to_monad
          status.failure? ? status : Success(self)
        end

        private

        attr_reader :mod, :field, :table_getter, :status

        def rows_to_vals(rows)
          result = rows.map{ |row| row.key?(field) ? row[field] : nil }
            .compact
            .sort
            .uniq
        rescue StandardError => err
          Failure(err)
        else
          Success(result)
        end

        def set_mod(mod)
          if mod.is_a?(Module)
            result = mod
          else
            result = Tms.const_get(mod)
          end
        rescue StandardError => err
          @status = Failure(err)
          nil
        else
          @status = Failure(:table_not_used) unless result.used?
          result
        end
      end
    end
  end
end
