# frozen_string_literal: true

module Kiba
  module Tms
    module Utils
      class PerTableJobRegistrar
        def self.call
          self.new.call
        end

        def initialize
          @to_register = gather
        end
        
        def call
          to_register.each{ |mod| mod.register_per_table_jobs }
        end

        private

        attr_reader :to_register

        def gather
          constants = Kiba::Tms.constants.select do |constant|
            evaled = Kiba::Tms.const_get(constant)
            evaled.is_a?(Module) &&
              evaled.respond_to?(:target_tables) &&
              evaled.respond_to?(:used?) &&
              evaled.used?
          end
          constants.map{ |const| Kiba::Tms.const_get(const) }
        end
      end
    end
  end
end
