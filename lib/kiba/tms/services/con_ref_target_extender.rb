# frozen_string_literal: true

module Kiba
  module Tms
    module Services
      class ConRefTargetExtender
        class << self
          def call(...)
            self.new(...).call
          end
        end

        def initialize(mod:, verbose: false)
          @mod = mod
          @verbose = verbose
          @extend_mod = Tms::Mixins::RolesMergedIn
        end

        def call
          mod.extend(extend_mod)
          puts "#{mod} extended with #{extend_mod}" if verbose
        end

        private

        attr_reader :mod, :verbose, :extend_mod
      end
    end
  end
end
