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
          @err_path = "#{Tms.datadir}/initial_config_errs.txt"
        end

        def call
          config = to_configure.map{ |const|
            Tms::Services::InitialConfigDeriver.call(mod: const)
          }
            .flatten
            .compact
            .group_by(&:success?)
          configs = config[true]
          errs = config[false]

          write_config(configs.map(&:value!)) if configs
          write_errs(errs.map(&:failure)) if errs
        end

        private

        attr_reader :to_configure, :config_path, :err_path

        def gather_configurable
          constants = Kiba::Tms.constants.select do |constant|
            evaled = Kiba::Tms.const_get(constant)
            evaled.is_a?(Module) && evaled.respond_to?(:used?)
          end
          constants.map{ |const| Kiba::Tms.const_get(const) }
        end

        def write_config(configs)
          File.open(config_path, 'w') do |file|
            configs.each{ |config| file.puts(config) }
        end
          end

        def write_errs(errs)
          File.open(err_path, 'w') do |file|
            errs.each{ |err| file.puts(err) }
          end
        end
      end
    end
  end
end
