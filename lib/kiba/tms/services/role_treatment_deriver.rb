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
        
        def initialize(mod)
          @mod = mod
          return unless eligible?

          @source_path = set_source_path
          @mapping = mod.con_role_treatment_mappings
          @mapped_roles = mapping.values.flatten
          @setting_name = "#{mod}.config.con_role_treatment_mappings"
        end

        def call
          return unless eligible?

          _path = yield(source_path)
          roles_get = yield(roles)

          @used_roles = roles_get

          if mapping.empty?
            Success("#{setting_name} = #{initial_treatment_hash(roles)}")
          else
            update_mapping
            Success(mapping)
          end
        end

        private

        attr_reader :mod, :source_path, :mapping, :mapped_roles, :setting_name, :used_roles

        def eligible?
          mod.respond_to?(:merges_roles?) && mod.merges_roles?
        end

        def initial_treatment_hash(roles)
          {unmapped: used_roles}
        end

        def new_roles
          used_roles - mapped_roles
        end
        
        def roles
          result = []
          CSV.foreach(source_path.value!, headers: true, header_converters: %i[downcase symbol]) do |row|
            table = row[:tablename]
            next unless table == mod.table_name

            role = row[:role]
            result << role unless result.any?(role)
          end
        rescue StandardError => err
          Failure([setting_name, err])
        else
          Success(result.sort)
        end
        
        def set_source_path
          source_key = Tms::ConRefs.for_table_source_job_key
          source = Tms.registry.resolve(source_key)
          source_path = source.path
          unless File.exist?(source_path)
            Kiba::Extend::Command::Run.job(source_key)
          end
        rescue StandardError => err
          Failure([setting_name, err])
        else
          Success(source_path)
        end

        def update_mapping
          to_update = new_roles
          return if to_update.empty?

          to_update.each{ |role| mapping[:unmapped] << role }
        end
      end
    end
  end
end
