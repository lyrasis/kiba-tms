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
          puts "Registering per-table jobs"
          to_register.each{ |mod| mod.register_per_table_jobs }
        end

        private

        attr_reader :to_register

        def gather
          Tms.configs.select do |config|
            config.respond_to?(:target_tables) &&
            config.respond_to?(:used?) &&
            config.used?
          end            
        end
      end
    end
  end
end
