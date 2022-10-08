# frozen_string_literal: true

module Kiba
  module Tms
    module Data
      class DeriverFailure

        attr_reader :mod

        # @param mod [Module]
        # @param name [String, NilValue]
        # @param sym [Symbol, NilValue]
        # @param err [Exception, NilValue]
        def initialize(mod:, name: nil, sym: nil, err: nil)
          @mod = mod
          @name = name
          @sym = sym
          @err = err.message if err
        end

        def formatted
          context = [mod, name].compact
            .join('.')
          [context, msg].reject(&:blank?)
            .join(': ')
        end

        private

        attr_reader :name, :err, :sym

        def msg
          [sym, err].compact
            .join(': ')
        end
      end
    end
  end
end
