# frozen_string_literal: true

module Kiba
  module Tms
    module Services
      class InitialConfigDeriver
        def self.call(...)
          self.new(...).call
        end
        
        def initialize(mod)
          @mod = mod
          @config = []
        end

        def call
          return nil unless mod.used?
          config << Tms::Services::InitialEmptyFieldDeriver.call(mod)
          derive_type_config if mod.respond_to?(:type_lookup) && mod.type_lookup
          derive_multi_table_merge_config if mod.respond_to?(:for?)
          derive_custom_config if mod.respond_to?(:configurable)
          config.compact
            .sort
        end

        private

        attr_reader :mod, :config

        def derive_custom_config
          mod.configurable.each do |setting, proc|
            config << "#{mod}.config.#{setting} = #{proc.call.inspect}"
          end
        end

        def derive_multi_table_merge_config
          tables = Tms::Services::TargetTableDeriver.call(mod)
          return unless tables
          
          config << "#{mod}.config.target_tables = #{tables.inspect}"
        end
        
        def derive_type_config
          config << Tms::Services::InitialTypeMappingDeriver.call(mod)
        end
      end
    end
  end
end
