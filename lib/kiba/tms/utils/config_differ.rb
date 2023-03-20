# frozen_string_literal: true

module Kiba
  module Tms
    module Utils
      # Removes unchanged configs from results.successes
      class ConfigDiffer
        include Dry::Monads[:result]

        def self.call(...)
          self.new(...).call
        end

        # @param results [Tms::Data::CompiledResult]
        def initialize(results)
          @results = results
        end

        def call
          return results if results.successes.empty?

          Tms::Data::CompiledResult.new(
            successes: different,
            failures: results.failures
          )
        end

        private

        attr_reader :results

        def different
          results.successes
            .map(&:value!)
            .each(&:diff)
            .reject{ |result| result.status == :unchanged }
            .map{ |result| Success(result) }
        end
      end
    end
  end
end
