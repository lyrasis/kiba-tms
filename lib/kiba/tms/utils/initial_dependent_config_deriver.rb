# frozen_string_literal: true

module Kiba
  module Tms
    module Utils
      class InitialDependentConfigDeriver
        def self.call(...)
          self.new(...).call
        end

        def initialize(
          derivers: [
            Tms::Utils::RoleTreatmentDeriver
          ],
          verbose: false
        )
          @derivers = derivers
          @verbose = verbose
          @config_path = "#{Tms.datadir}/initial_config_dependent.txt"
          @err_path = "#{Tms.datadir}/initial_config_errs_dependent.txt"
        end

        def call
          all = derivers.map(&:call)
            .flatten
            .compact
            .group_by(&:success?)

          handle_successes(all)
          handle_failures(all)
        end

        private

        attr_reader :derivers, :verbose, :config_path, :err_path

        def handle_failures(all)
          list = all[false]
          return unless list
          return if list.empty?

          puttable = list.map(&:failure).join("\n\n")
          File.open(err_path, 'w'){ |f| f.puts(puttable) }
          puts "\n\nERRORS" if verbose
          puts puttable if verbose
        end

        def handle_successes(all)
          list = all[true]
          return unless list
          return if list.empty?

          puttable = list.map(&:value!).join("\n")
          File.open(config_path, 'w'){ |f| f.puts(puttable) }
          puts puttable if verbose
        end
      end
    end
  end
end
