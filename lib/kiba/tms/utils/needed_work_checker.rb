# frozen_string_literal: true

module Kiba
  module Tms
    module Utils
      class NeededWorkChecker
        def self.call
          self.new.call
        end

        def initialize
          @to_check = gather_checkable
          @path = Tms.datadir
        end
        
        def call
          to_check.map{ |config| run_checks(config.checkable.values) }
            .flatten
            .compact
            .each{ |res| puts res }
        end

        private

        attr_reader :to_check

        def gather_checkable
          Tms.configs.select{ |config| config.respond_to?(:checkable) }
        end

        def run_checks(checks)
          checks.map{ |check| check.call }
        end
      end
    end
  end
end
