# frozen_string_literal: true

module Kiba
  module Tms
    module Utils
      # Gathers config modules for tables that get ConRefs and their roles
      #   merged in and calls single module RoleTreatmentDeriver on each
      class RoleTreatmentDeriver
        def self.call(...)
          new(...).call
        end

        def initialize(deriver: Tms::Services::RoleTreatmentDeriver)
          @deriver = deriver
          @configs = gather_configs
        end

        def call
          configs.map do |config|
            deriver.call(mod: config)
          end
        end

        private

        attr_reader :deriver, :configs

        def gather_configs
          Tms.configs.select do |constant|
            constant.respond_to?(:gets_roles_merged_in?)
          end
        end
      end
    end
  end
end
