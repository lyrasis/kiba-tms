# frozen_string_literal: true

module Kiba
  module Tms
    module Data
      class CompiledResult
        attr_reader :successes, :failures

        def initialize(successes: [], failures: [])
          @successes = successes.map(&:value!).sort
          @failures = failures.reject{ |err| err.failure.sym == :not_used }
            .sort_by{ |err| err.failure.mod }
        end

        def output
          successes.each{ |success| puts success.to_s }
          return if failures.empty?

          puts "\n\nFAILURES"
          failures.each do |err|
            puts err.failure.formatted
            puts err.trace
            puts ''
          end
        end

        def output_to(path)
          File.open(path, 'w') do |file|
          successes.each{ |success| file.puts(success.to_s) }
          return if failures.empty?

          puts "\n\nFAILURES"

            failures.each{ |err| file.puts(err.formatted) }
          end
        end
      end
    end
  end
end
