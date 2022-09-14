# frozen_string_literal: true

module Kiba
  module Tms
    module Utils
      class UnmappedTypeValueChecker
        def self.call
          self.new.call
        end

        def initialize
          @to_check = gather_checkable
        end
        
        def call
          to_check.map{ |const| Tms::Services::UnmappedTypeValueChecker.call(const) }
            .compact
            .flatten
            .sort
            .each{ |unmapped| puts unmapped }
        end

        private

        attr_reader :to_check

        def gather_checkable
          constants = Kiba::Tms.constants.select do |constant|
            evaled = Kiba::Tms.const_get(constant)
            evaled.is_a?(Module) &&
              evaled.ancestors.any?(Dry::Configurable) &&
              used?(evaled) &&
              evaled.config.values.key?(:type_lookup) &&
              evaled.config.values.key?(:mappings)
          end
          constants.map{ |const| Kiba::Tms.const_get(const) }
        end

        # temp method while both :used and :used? are in play
        def used?(evaled)
          return true if evaled.respond_to?(:used?) && evaled.used?

          return true if evaled.respond_to?(:used) && evaled.used
        end
      end
    end
  end
end
