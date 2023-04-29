# frozen_string_literal: true

module Kiba
  module Tms
    module Utils
      class InitialDependentConfigDeriver
        def self.call(...)
          new(...).call
        end

        def initialize(
          derivers: [
            Tms::Utils::RoleTreatmentDeriver
          ],
          resobj: Tms::Data::CompiledResult,
          verbose: false,
          mode: :stdout
        )
          @derivers = derivers
          @verbose = verbose
          @resobj = resobj
          @path = "#{Tms.datadir}/initial_config_dependent.txt"
          @mode = mode
        end

        def call
          all = derivers.map(&:call)
            .compact
            .flatten
          return resobj.new if all.blank?

          result = resobj.new(
            successes: all.select(&:success?),
            failures: all.select(&:failure?)
          )

          handle_output(result)
        end

        private

        attr_reader :derivers, :verbose, :resobj, :path, :mode

        def handle_output(result)
          if mode == :stdout
            result.output
          else
            result.output_to(path)
          end
        end
      end
    end
  end
end
