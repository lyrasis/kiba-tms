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
          parts = str.split('.')
          col.new(mod: parts[0], field: parts[1])
        end

        private

        attr_reader :str, :col
      end
    end
  end
end
