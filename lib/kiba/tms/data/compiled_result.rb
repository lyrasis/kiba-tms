# frozen_string_literal: true

module Kiba
  module Tms
    module Data
      class CompiledResult
        def initialize(successes: [], failures: [])
          @successes = successes.map(&:value!).sort
          @failures = failures.sort_by{ |f| f.failure.mod }
        end

        def output
          successes.each{ |success| puts success.to_s }
          return if failures.empty?

          puts "\n\nFAILURES"
          failures.each{ |f| puts f.formatted }
        end

        def output_to(path)
          File.open(path, 'w') do |file|
          successes.each{ |success| file.puts(success.to_s) }
          return if failures.empty?

          puts "\n\nFAILURES"
          failures.each{ |f| file.puts(f.formatted) }

          end
        end

        private

        attr_reader :successes, :failures

      end
    end
  end
end
