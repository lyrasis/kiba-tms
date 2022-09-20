# frozen_string_literal: true

module Kiba
  module Tms
    module Services
      class EmptyFieldsChecker
        def self.call(...)
          self.new(...).call
        end

        # @param table [Kiba::Tms::Table::Obj]
        # @param mod [Module]
        def initialize(table, mod)
          @table = table
          @mod = mod
          @empty_fields = mod.send(:empty_fields)
          @empty = []
          @not_empty = []
        end

        def call
          empty_fields.each{ |field| check(field) }
          if not_empty.empty?
            Tms::Data::EmptyFieldsCheckerResult.new(status: :success, mod: mod)
          else
            Tms::Data::EmptyFieldsCheckerResult.new(
              status: :failure,
              mod: mod,
              empty: empty,
              not_empty: not_empty
            )
          end
        end

        private

        attr_reader :table, :mod, :empty_fields, :empty, :not_empty

        def check(field)
          result = EmptyFieldChecker.call(table, mod, field)
          return unless result

          result == :success ? empty << field : not_empty << field
        end
      end
    end
  end
end
