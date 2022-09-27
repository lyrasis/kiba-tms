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
              if result.is_a?(Dry::Monads::Result)
                successful_custom_config_monad(setting_name, result)
              else
                successful_custom_config_non_monad(setting_name, result)
              end
            end
          end
        end

        def successful_custom_config_monad(setting_name, result)
          result.either(
            ->success{
              config << Success("#{setting_name} = #{success.inspect}")
            },
            ->failure{ config << Failure([setting_name, failure]) }
          )
        end

        def successful_custom_config_non_monad(setting_name, result)
          warn("#{setting_name} auto-config should return Dry::Monads::Result")
          config << Success("#{setting_name} = #{result.inspect}")
        end

        def derive_multi_table_merge_config
          setting_name = "#{mod}.config.target_tables"
          begin
            tables = Tms::Services::TargetTableDeriver.call(mod: mod)
          rescue StandardError => err
            config << Failure([setting_name, err])
          else
            return nil unless tables

            tables.either(
              ->(success){
                config << Success("#{setting_name} = #{success.inspect}")
              },
              ->(failure){ config << Failure([setting_name, failure]) }
            )
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
