# frozen_string_literal: true

require "csv"
require "dry/monads"
require "dry/monads/do"

module Kiba
  module Tms
    module Services
      class TypeMappingDeriver
        include Dry::Monads[:result]
        include Dry::Monads::Do.for(:call)

        def self.call(...)
          self.new(...).call
        end

        def initialize(mod:,
                       settingobj: Tms::Data::ConfigSetting,
                       failobj: Tms::Data::DeriverFailure,
                       getter: UniqueTypeValuesUsed
                      )
          @mod = mod
          @settingobj = settingobj
          @failobj = failobj
          @getter = getter
          return eligible? if eligible?.failure?

          @id_field = mod.id_field
          @type_field = mod.type_field
          @no_val_remover = Tms::Transforms::DeleteNoValueTypes.new(
            field: type_field
          )
          @setting = :mappings
          @current_mappings = mod.mappings
        end

        def call
          _eligible = yield eligible?

          raw_values = yield getter.call(mod: mod)
          derived_hash = yield(mapping_hash(raw_values))

          Success(settingobj.new(
            mod: mod,
            name: setting,
            value: derived_hash.merge(current_mappings)
          ))
        end

        private

        attr_reader :mod, :settingobj, :failobj, :getter,
          :id_field, :type_field, :no_val_remover,
          :setting, :current_mappings

        def eligible?
          failure = Failure(
            failobj.new(mod: mod, name: setting, sym: :not_eligible)
          )
          return failure unless mod.respond_to?(:is_type_lookup_table?)

          if mod.is_type_lookup_table?
            Success()
          else
            failure
          end
        end

        def default_mapped(value)
          case mod.default_mapping_treatment
          when :self
            value
          when :downcase
            value.downcase
          when :todo
            "TODO: provide mapping"
          end
        end

        def mapping_hash(values)
          result = values.map{ |val| [val, default_mapped(val)] }.to_h
        rescue StandardError => err
          Failure(
            failobj.new(mod: mod, name: setting, err: err)
          )
        else
          Success(result)
        end
      end
    end
  end
end
