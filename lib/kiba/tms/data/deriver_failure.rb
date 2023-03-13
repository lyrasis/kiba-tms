# frozen_string_literal: true

module Kiba
  module Tms
    module Data
      class DeriverFailure

        attr_reader :mod, :name, :err, :sym

        # @param mod [Module]
        # @param name [String, NilValue]
        # @param sym [Symbol, NilValue]
        # @param err [Exception, NilValue]
        def initialize(mod:, name: nil, sym: nil, err: nil)
          @mod = mod
          @name = name
          @sym = sym
          @err = err.message if err
          @trace = err.backtrace.first(3) if err
        end

        def formatted
          context = [mod, name].compact
            .join('.')
          with_msg = [context, msg].reject(&:blank?)
            .join(': ')
          [with_msg, backtrace].reject(&:blank?)
            .join("\n")
        end

        private

        attr_reader :trace

        def backtrace
          return nil unless trace

          trace.map{ |line| "   #{line}" }
            .join("\n")
        end

        def msg
          [sym, err].compact
            .join(': ')
        end
      end
    end
  end
end
