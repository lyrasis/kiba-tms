# frozen_string_literal: true

module Kiba
  module Tms
    module Services
      class TableMergesToDo
        def self.call(...)
          new(...).call
        end

        def initialize(mod)
          @mod = mod
          @src = Tms.table_merge_status
          @target = mod.table_name
        end

        def call
          return [] if src.blank?
          return [] unless src.key?(target)

          src[target].select { |table, status| status == :todo }
            .keys
            .map { |key| "#{target}: merge into from #{key}" }
        end

        private

        attr_reader :mod, :src, :target
      end
    end
  end
end
