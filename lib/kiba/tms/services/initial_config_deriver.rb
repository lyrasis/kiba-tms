# frozen_string_literal: true

require 'dry/monads'

module Kiba
  module Tms
    module Services
      class InitialConfigDeriver
        include Dry::Monads[:result]
        
        def self.call(...)
          self.new(...).call
        end
        
        def initialize(mod)
          @mod = mod
          @config = []
        end

        def call
          puts "Deriving config for #{mod}..."
          return nil unless mod.used?
          config << Tms::Services::InitialEmptyFieldDeriver.call(mod)
          derive_type_config if mod.respond_to?(:mappable_type?)
          derive_multi_table_merge_config if mod.respond_to?(:for?)
          derive_custom_config if mod.respond_to?(:configurable)
          config.compact
        end

        private

        attr_reader :mod, :config

        def derive_custom_config
          mod.configurable.each do |setting, proc|
            begin
              setting_name = "#{mod}.config.#{setting}"
              result = proc.call
            rescue StandardError => err
              config << Failure([setting_name, err])
            else
              config << Success("#{setting_name} = #{result.inspect}")
            end
          end
        end

        def derive_multi_table_merge_config
          setting_name = "#{mod}.config.target_tables"
          begin
            tables = Tms::Services::TargetTableDeriver.call(mod)
          rescue StandardError => err
            config << Failure([setting_name, err])
          else
            return unless tables
            
            config << Success("#{setting_name} = #{tables.inspect}")
          end
        end

        def derive_type_config
          if mod.mappable_type?
            config << Tms::Services::TypeMappingDeriver.call(mod)
          else
            config << Tms::Services::TypeTableKnownValueDeriver.call(mod)
          end
        end
      end
    end
  end
end
