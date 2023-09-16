# frozen_string_literal: true

module Kiba
  module Tms
    module Utils
      class ForTableTypeCleanupExtender
        class << self
          def call(...)
            new(...).call
          end
        end

        def initialize(
          extender: Tms::Services::ModuleExtender,
          verbose: false
        )
          @extender = extender.new(extend_mod: Tms::Mixins::ForTableTypeCleanup,
            verbose: verbose)
          @extendable = gather_extendable
        end

        def call
          extendable.each do |mod|
            extender.call(mod)
          end
        end

        private

        attr_reader :extender, :verbose, :configs, :extendable

        def gather_extendable
          Tms.configs
            .select do |cfg|
              cfg.respond_to?(:type_cleanable?) && cfg.type_cleanable?
            end
        end
      end
    end
  end
end
