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

        def initialize(mod:, col: Tms::Data::Column)
          @mod = mod
          return unless eligible?

          @setting = :con_role_treatment_mappings
          @role_mod = Tms.const_get("ConRefsFor#{mod.table_name}")
          @col = col.new(mod: role_mod, field: :role)
          @current_mapping = mod.send(setting)
          @known_roles = current_mapping.reject{ |key, _v| key == :unmapped }
            .values
            .flatten
        end

        def call
          return unless eligible?

          roles = yield(col.unique_values)
          @new_roles = roles - known_roles
          result = yield(formatted)

          Success(result)
        end

        private

        attr_reader :mod, :setting, :role_mod, :col, :current_mapping,
          :known_roles, :new_roles

        def formatted
          result = [
            "#{mod}.config.#{setting} = {",
            hash_lines,
            '}'
          ].join("\n")
        rescue StandardError => err
          Failure([setting, err])
        else
          Success(result)
        end

        def hash_lines
          mapping_hash.map{ |key, val| "#{key}: #{val.inspect}" }
          .join(",\n")
        end

        def mapping_hash
          current_mapping.merge(new_role_hash)
        end

        def eligible?
          m = :gets_roles_merged_in?
          mod.respond_to?(m) && mod.send(m)
        end

        def new_role_hash
          {unmapped: new_roles}
        end

      end
    end
  end
end
