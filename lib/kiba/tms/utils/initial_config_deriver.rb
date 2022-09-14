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
        end
        
        def call
          config = to_configure.map{ |const| Tms::Services::InitialConfigDeriver.call(const) }
            .flatten
            .sort
          binding.pry
        end

        private

        attr_reader :to_configure

        def gather_configurable
          constants = Kiba::Tms.constants.select do |constant|
            evaled = Kiba::Tms.const_get(constant)
            evaled.is_a?(Module) && evaled.ancestors.any?(Kiba::Tms::Mixins::Tableable)
          end
          constants.map{ |const| Kiba::Tms.const_get(const) }
        end
      end
    end
  end
end
