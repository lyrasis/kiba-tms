# frozen_string_literal: true

module Kiba
  module Tms
    module Utils
      class ForTableJobRegistrar
        def self.call
          new.call
        end

        def initialize
          @to_register = gather
        end

        def call
          puts "Registering for_table jobs"
          to_register.each do |mod|
            mod.register_for_table_jobs
          end
          puts "Registering reportable for_table jobs"
          to_register.each do |mod|
            mod.register_reportable_for_table_jobs
          end
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
