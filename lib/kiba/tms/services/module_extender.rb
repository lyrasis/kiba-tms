# frozen_string_literal: true

module Kiba
  module Tms
    module Services
      class ModuleExtender
        def initialize(extend_mod)
          @extend_mod = extend_mod
        end

        def call(target_mod)
          target_mod.extend(extend_mod)
          puts "#{target_mod} extended with #{extend_mod}" if Tms.verbose?
        end

        private

        attr_reader :extend_mod
      end
    end
  end
end
