# frozen_string_literal: true

module Kiba
  module Tms
    module Mixins
      # Methods used by {MultiTableMergeable} to setup type cleanup for
      #   for-tables listed in `target_table_type_cleanup_needed`
      #
      # ## Required settings
      #
      # - `type_field`
      # - `mergeable_value_field`
      #
      # ## Optional settings
      #
      # - `type_field_target`
      # - `additional_occurrence_ct_fields`
      #
      # See {MultiTableMergeable} for full description of these settings
      module ForTableTypeCleanup
        def self.extended(mod)
          mod.send(:define_for_table_modules)
        end

        def define_for_table_modules
          target_table_type_cleanup_needed.each do |table|
            define_for_table_module(table)
          end
        end
        private :define_for_table_modules

        def define_for_table_module(table)
          tableobj = Tms::Table::Obj.new(table)
          modname = fttc_mod_name(table)
          return if fttc_mod_exist?(modname)
        end
        private :define_for_table_module

        def fttc_mod_name(table)
          parent = name.split("::").last
          "#{parent}For#{table}TypeCleanupAuto"
        end
        private :fttc_mod_name

        def fttc_mod_exist?(name)
          Tms.constants.include?(name.to_sym)
        end
      end
    end
  end
end
