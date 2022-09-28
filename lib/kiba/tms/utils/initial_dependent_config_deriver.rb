# frozen_string_literal: true

module Kiba
  module Tms
    module Utils
      class InitialDependentConfigDeriver
        def self.call
          self.new.call
        end

        def initialize
          @to_configure = gather_configurable
          @config_path = "#{Tms.datadir}/initial_config_dependent.txt"
          @err_path = "#{Tms.datadir}/initial_config_errs_dependent.txt"
        end

        def call
          config = to_configure.map{ |const| Tms::Services::RoleTreatmentDeriver.call(const) }
            .flatten
            .compact
            .group_by(&:success?)
          configs = config[true].map(&:value!)
          errs = config[false].map(&:failure)

          write_config(configs) unless configs.empty?
          write_errs(errs) unless errs.empty?
          binding.pry
        end

        private

        attr_reader :to_configure, :config_path, :err_path

        def gather_configurable
          Tms.configs.select do |constant|
            constant.respond_to?(:gets_roles_merged_in?)
          end
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
