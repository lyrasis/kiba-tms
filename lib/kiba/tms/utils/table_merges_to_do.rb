# frozen_string_literal: true

module Kiba
  module Tms
    module Utils
      class TableMergesToDo
        def self.call(...)
          new(...).call
        end

        def initialize(checker = Tms::Services::TableMergesToDo)
          @checker = checker
          @src = Tms.table_merge_status
        end

        def call
          src.keys
            .map { |key| Tms.const_get(key) }
            .map { |mod| checker.call(mod) }
            .flatten
        end

        private

        attr_reader :checker, :src
      end
    end
  end
end
