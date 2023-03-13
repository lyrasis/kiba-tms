# frozen_string_literal: true

module Kiba
  module Tms
    module Utils
      class InitialConfigDeriver
        def self.call
          self.new.call
        end

        def initialize
          @to_configure = gather_configurable
          @config_path = "#{Tms.datadir}/initial_config.txt"
        end

        def call
          starttime = Time.now
          @configs = to_configure.map{ |const|
            Tms::Services::InitialConfigDeriver.call(mod: const)
          }
          elapsedtime = (Time.now - starttime) / 60
          puts "Duration: #{elapsedtime} minutes"

          Tms::Data::CompiledResult.new(
            successes: all_successes,
            failures: all_errors
          ).output_to(config_path)
        end

        private

        attr_reader :to_configure, :config_path, :configs

        def gather_configurable
          constants = Kiba::Tms.constants.select do |constant|
            evaled = Kiba::Tms.const_get(constant)
            evaled.is_a?(Module) && evaled.respond_to?(:used?)
          end
          constants.map{ |const| Kiba::Tms.const_get(const) }
            .sort_by{ |mod| mod.to_s }
        end

        def all_errors
          configs.map(&:failures)
            .flatten
        end

        def all_successes
          configs.map(&:successes)
            .flatten
        end
      end
    end
  end
end
