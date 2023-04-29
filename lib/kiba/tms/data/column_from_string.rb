# frozen_string_literal: true

module Kiba
  module Tms
    module Data
      class ColumnFromString

        class << self
          def call(...)
            self.new(...).call
          end
        end

        # @param str [String] like "TableName.field_name"
        # @param col [Class]
        def initialize(str:, col: Tms::Data::Column)
          @str = str
          @col = col
        end

        def call
          parts = str.split(".")
          mod = parts[0]
          check_mod(mod)
          col.new(mod: parts[0], field: parts[1])
        end

        private

        attr_reader :str, :col

        def check_mod(mod)
          unless Tms.configs.any?{ |cfg| cfg.to_s.end_with?("::#{mod}") }
            fail(Tms::UnconfiguredModuleError.new(mod.to_s))
          end
        end
      end
    end
  end
end
