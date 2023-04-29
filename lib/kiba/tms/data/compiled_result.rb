# frozen_string_literal: true

module Kiba
  module Tms
    module Data
      class CompiledResult
        attr_reader :successes, :failures

        def initialize(successes: [], failures: [])
          @successes = successes.sort_by{ |success| success.value! }
          @failures = failures.reject{ |err| err.failure.sym == :not_used }
            .sort_by{ |err| err.failure.mod.to_s }
        end

        def output
          successes.each{ |success| puts success.value!.to_s }
          return if failures.empty?

          puts "\n\nFAILURES"
          failures.each do |err|
            puts err.failure.formatted
            puts err.trace
            puts ""
          end
        end

        def output_to(path)
          File.open(path, "w") do |file|
            successes.each{ |success| file.puts(success.value!.to_s) }
            return if failures.empty?

            file.puts("\n\nFAILURES")
            failures.each{ |err| file.puts(err.failure.formatted) }
          end
        end
      end
    end
  end
end
