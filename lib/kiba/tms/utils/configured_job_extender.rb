# frozen_string_literal: true

module Kiba
  module Tms
    module Utils
      # Extends all jobs defined in Tms::Jobs with their relevant config
      #   modules
      class ConfiguredJobExtender
        class << self
          def call(...)
            new(...).call
          end
        end

        def initialize(
          extender: Tms::Services::ConfiguredJobExtender,
          verbose: false
        )
          @extender = extender
          @verbose = verbose
          @configs = prep_configs
          @extendable = prep_extendable
        end

        def call
          extendable.each do |namespace|
            extender.call(namespace: namespace, verbose: verbose)
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
                .to_sym
            end
        end

        def prep_extendable
          Tms::Jobs.constants
            .select { |const| configs.any?(const) }
        end
      end
    end
  end
end
