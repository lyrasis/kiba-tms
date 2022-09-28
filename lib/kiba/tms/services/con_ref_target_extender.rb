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
          mod.module_eval(setting)
        end

        private

        attr_reader :mod, :verbose, :extend_mod

        def setting
          "setting :con_role_treatment_mappings, default: {}, reader: true"
        end
      end
    end
  end
end
