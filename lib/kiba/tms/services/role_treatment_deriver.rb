# frozen_string_literal: true

require 'csv'
require 'dry/monads'
require 'dry/monads/do'

module Kiba
  module Tms
    module Services
      class RoleTreatmentDeriver
        include Dry::Monads[:result]
        include Dry::Monads::Do.for(:call)

        def self.call(...)
          self.new(...).call
        end

        def initialize(mod:,
                       col: Tms::Data::Column,
                       settingobj: Tms::Data::ConfigSetting,
                       failobj: Tms::Data::DeriverFailure
                      )
          @mod = mod
          return unless eligible?

          @colobj = col
          @settingobj = settingobj
          @failobj = failobj
          @setting = :con_role_treatment_mappings
          @current_mapping = mod.send(setting)
          @known_roles = current_mapping.reject{ |key, _v| key == :unmapped }
            .values
            .flatten
        end

        def call
          _eligible = yield eligible?
          role_mod = yield get_role_mod
          col = yield get_column(role_mod)
          roles = yield col.unique_values
          @new_roles = roles - known_roles

          Success(settingobj.new(
            mod: mod,
            name: setting,
            value: mapping_hash
          ))
        end

        private

        attr_reader :mod, :colobj, :settingobj, :failobj, :setting,
          :current_mapping, :known_roles, :new_roles

        def eligible?
          meth = :gets_roles_merged_in?

          unless mod.respond_to?(meth)
            Failure(
              failobj.new(mod: mod,
                                name: setting,
                                sym: :missing_eligibility_setting
                         )
            )
          end

          val = mod.send(meth)
          if val
            Success()
          else
            Failure(failobj.new(mod: mod,
                                name: setting,
                                sym: :not_eligible)
                   )
          end
        end

        def get_column(role_mod)
          result = colobj.new(mod: role_mod, field: :role)
        rescue StandardError => err
          Failure(
            failobj.new(mod: mod, name: setting, err: err)
          )
        else
          Success(result)
        end

        def get_role_mod
          result = Tms.const_get("ConRefsFor#{mod.table_name}")
        rescue StandardError => err
          Failure(
            failobj.new(mod: mod, name: setting, err: err)
          )
        else
          Success(result)
        end

        def mapping_hash
          current_mapping.merge({unmapped: new_roles})
        end
      end
    end
  end
end
