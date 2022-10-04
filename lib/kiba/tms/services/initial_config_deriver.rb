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

        def initialize(mod:,
                       empty_deriver: EmptyFieldsDeriver,
                       mapping_deriver: TypeMappingDeriver,
                       known_val_deriver: TypeTableKnownValueDeriver,
                       target_table_deriver: TargetTableDeriver,
                       failobj: Tms::Data::DeriverFailure,
                       resobj: Tms::Data::CompiledResult
                      )
          @mod = mod
          @empty_deriver = empty_deriver
          @mapping_deriver = mapping_deriver
          @known_val_deriver = known_val_deriver
          @target_table_deriver = target_table_deriver
          @failobj = failobj
          @resobj = resobj
        end

        def call
          puts "Deriving config for #{mod}..."
          unless mod.used?
            return resobj.new(
              failures: [Failure(failobj.new(mod: mod, sym: :not_used))]
            )
          end

          results = configs.map(&:call)
          return resobj.new if results.blank?

          resobj.new(
            successes: results.select(&:success?),
            failures: results.select(&:failure?)
          )
        end

        private

        attr_reader :mod, :empty_deriver, :mapping_deriver, :known_val_deriver,
          :target_table_deriver, :failobj, :resobj

        def configs
          base = []
          if mod.respond_to?(:is_tableable?)
            base << proc{ empty_deriver.call(mod: mod) }
          end

          if mod.respond_to?(:is_type_lookup_table?)
            if mod.mappable_type?
              base << proc{ mapping_deriver.call(mod: mod) }
            else
              base << proc{ known_val_deriver.call(mod: mod) }
            end
          end

          if mod.respond_to?(:is_multi_table_mergeable?)
            base << proc{ target_table_deriver.call(mod: mod) }
          end

          base
        end

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

      end
    end
  end
end
