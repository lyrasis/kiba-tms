# frozen_string_literal: true

module Kiba
  module Tms
    module Data
      class DeriverFailure
        # @param mod [Module]
        # @param name [String, NilValue]
        # @param sym [Symbol, NilValue]
        # @param err [Exception, NilValue]
        def initialize(mod:, name: nil, sym: nil, err: nil)
          @mod = mod
          @name = name
          @sym = sym
          @err = err.msg if err
        end

        def formatted
        end

        private

        attr_reader :mod, :name, :err, :sym

        def msg
          [sym, err].join(': ')
        end
      end
    end
  end
end
