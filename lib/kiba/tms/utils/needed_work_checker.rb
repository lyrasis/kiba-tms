# frozen_string_literal: true

module Kiba
  module Tms
    module Utils
      # Report on needed work left to do in all modules with auto-checks set up.
      #   Different from PostDataUpdateChecker in that this assumes the TMS data
      #   we are working with has *not* changed.
      #
      # This is intended to highlight where migration development is incomplete,
      #   given the known set of data.
      #
      # PostDataUpdateChecker highlights where new migration development tasks
      #   are required, due to changes in the data.
      class NeededWorkChecker
        def self.call(...)
          self.new(...).call
        end

        def initialize(checker = Tms::Services::NeededWorkChecker)
          @checker = checker
          @to_check = Tms.checkable_tables
        end

        def call
          results = to_check.map{ |mod| checker.call(mod) }
          handle_successes(extract(results, :successes))
          #          needed_merges
          binding.pry
          handle_failures(extract(results, :failures))
        end

        private

        attr_reader :checker, :to_check

        def extract(results, type)
          results.reject{ |res| res.send(type).empty? }
            .map{ |res| [res.mod, res.send(type)] }
            .to_h
        end

        def handle_successes(results)
          return if results.empty?

          results.each do |mod, msgs|
            puts(mod)

            msgs.each{ |msg| puts("  #{msg}") }
          end
        end

        def handle_failures(results)
          return if results.compact.empty?

          puts("\n\nERRORS")

          results.each do |mod, fails|
            next if fails.compact.empty?

            puts(mod)
            fails.each{ |f| puts "  #{f[0]}\n    #{f[1]}" }
          end
        end
      end
    end
  end
end
