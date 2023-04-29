# frozen_string_literal: true

module Kiba
  module Tms
    module Utils
      class ConRefTargetExtender
        class << self
          def call(...)
            new(...).call
          end
        end

        def initialize(
          extender: Tms::Services::ConRefTargetExtender,
          verbose: false
        )
          @extender = extender
          @verbose = verbose
          @configs = prep_configs
          @extendable = prep_extendable
        end

        def call
          extendable.each do |mod|
            extender.call(mod: mod, verbose: verbose)
          end
        end

        private

        attr_reader :extender, :verbose, :configs, :extendable

        def prep_configs
          Tms.configs
            .map do |config|
              config.to_s
                .split("::")
                .last
            end
        end

        def prep_extendable
          Tms::ConRefs.target_tables
            .select { |table| configs.any?(table) }
            .map { |table| Tms.const_get(table) }
        end
      end
    end
  end
end
