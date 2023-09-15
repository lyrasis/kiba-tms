# frozen_string_literal: true

module Kiba
  module Tms
    module Services
      class ModuleExtender
        def initialize(extend_mod:, verbose: false)
          @extend_mod = extend_mod
          @verbose = verbose
        end

        def call(target_mod)
          target_mod.extend(extend_mod)
          puts "#{target_mod} extended with #{extend_mod}" if verbose
        end

        private

        attr_reader :extend_mod, :verbose
      end
    end
  end
end
