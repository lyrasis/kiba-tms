# frozen_string_literal: true

module Kiba
  module Tms
    module Utils
      class ForTableEmptyTypeCleanupExtender
        class << self
          def call(...)
            new(...).call
          end
        end

        def initialize(
          extender: Tms::Services::ModuleExtender
        )
          @extender = extender.new(Tms::Mixins::ForTableEmptyTypeCleanup)
          @extendable = gather_extendable
        end

        def call
          extendable.each do |mod|
            extender.call(mod)
          end
        end

        private

        attr_reader :extender, :configs, :extendable

        def gather_extendable
          Tms.configs
            .select do |cfg|
              cfg.respond_to?(:empty_type_cleanable?) &&
                cfg.empty_type_cleanable?
            end
        end
      end
    end
  end
end
