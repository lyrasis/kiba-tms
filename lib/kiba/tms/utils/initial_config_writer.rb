# frozen_string_literal: true

module Kiba
  module Tms
    module Utils
      # Outputs results of Utils::InitialConfigDeriver to file
      class InitialConfigWriter
        def self.call(...)
          self.new(...).call
        end

        # Where config will be written
        DEFAULT_PATH = File.join(Tms.datadir, "initial_config.txt")

        # @param results [Tms::Data::CompiledResult]
        # @param path [String]
        def initialize(results:, path: DEFAULT_PATH)
          @results = results
          @path = File.expand_path(path)
        end

        def call
          results.output_to(path)
        end

        private

        attr_reader :results, :path
      end
    end
  end
end
