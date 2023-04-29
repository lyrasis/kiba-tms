# frozen_string_literal: true

require "dry/monads"

module Kiba
  module Tms
    module Services
      # Report on needed work left to do in/for the given module.
      #
      # For differentiation from PostDataUpdateChecker, see corresponding wrapper
      #   class in Utils namespace.
      class NeededWorkChecker
        include Dry::Monads[:result]

        def self.call(...)
          new(...).call
        end

        attr_reader :mod

        def initialize(mod)
          @mod = mod
          @to_check = mod.checkable
          @results = []
        end

        def call
          to_check.each { |name, check| run(check, name) }
          self
        end

        def failures
          @failures ||= results.select(&:failure?)
            .map(&:failure)
        end

        def successes
          @successes ||= results.select(&:success?)
            .reject { |succ| succ.value!.nil? }
            .map(&:value!)
        end

        private

        attr_reader :to_check, :results

        def run(check, name)
          result = check.call
        rescue => err
          results << Failure([name, err])
        else
          results << if result.is_a?(Dry::Monads::Result)
            result
          else

            Success(result)
          end
        end
      end
    end
  end
end
