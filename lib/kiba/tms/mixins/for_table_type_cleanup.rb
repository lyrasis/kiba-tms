# frozen_string_literal: true

module Kiba
  module Tms
    module Mixins
      # Methods used by {MultiTableMergeable} to setup type cleanup for
      #   for-tables listed in `target_table_type_cleanup_needed`
      #
      # ## Required settings if f
      #
      # #### `type_field`
      #
      #
      # As mentioned above, this will generally be set in the Kiba::Tms
      #   config module for the table, because, in general, for example, for
      #   TextEntries, the value will be `:textype`. If a specific client
      #   has done something like record the types in the `:purpose` field,
      #   you can override this in client project config.
      #
      # If a client has not entered types at all, they will not need to do
      #   type cleanup or treatment indication. (Unless they want to). Turn
      #   off default type processing by overriding `type_field` in client
      #   project config with `nil`
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
