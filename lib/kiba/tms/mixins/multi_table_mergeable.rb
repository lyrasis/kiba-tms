# frozen_string_literal: true

# Mixin module for consistently handling multi-table mergeable
#   data tables.
#
# One example of a MultiTableMergeable table typically used in TMS
#   instances is TextEntries. This table stores long text values that
#   may need to be merged into data in Objects, Constituents,
#   ReferenceMaster, or many other tables.
#
# Target tables are the other tables that data from a
#   MultiTableMergeable table needs to be merged into.
#
# This module provides methods for setting up config settings in the
#   module, generating auto-configuration settings, running config
#   checks, and registering jobs to (a) break the original table up
#   into tables for each target--"for-tables"; and (b) merge
#   human-readable ids from the main target tables into the mergable
#   "for" tables--"reportable-for-tables". (Example: merge
#   objectnumber values into alt_nums_for__objects)
#
# It also provides a pattern for triggering setup of for-table type cleanup and
#   treatment definition routines for config modules where this is necessary.
#
# ## Usage
#
# Modules mixing this in must:
#
# - `extend Tms::Mixins::MultiTableMergeable`
#
# ### Optional settings/methods set ***before*** extending
#
# The following settings are optional, but, if used, must be defined
#   ***before*** this module is extended.
#
# These settings generally seem inherent to the TMS data structure and
#   shouldn't usually need to be overridden in client project config.
#   `type_field` may be an exception to this rule, if a client has
#   done something strange in their data entry.
#
# #### `for_table_source_job_key`
#
# Defines the full registry entry key for the job that will be used a
#   the base multi-table-mergeable table. This is the table that will
#   get split into separate for-tables.
#
# If this is not set before extending, extension will set it to the
#   prep job for the extending config module. So, if `AltNums` is
#   extending, it will be set to `:prep__alt_nums`.
#
# #### `split_on_column`
#
# In most multi-table-mergeable tables, the original TMS data has a
#   `tableid` field. The migration prep job for these tables usually
#   runs the {Tms::Transforms::TmsTableNames} transform, which
#   converts `tableid` to a human-readable `tablename` column that
#   matches the TMS table name and associated config module in the
#   migration.
#
# For this reason, if you don't define this setting/method prior to
#   extending, extension will set it to `:tablename`. See
#   {Kiba::Tms::ConRefs} for an example of an overriding config
#   module.
#
# #### `type_field`
#
# Some multi-table mergeable tables include information on the type of
#   data recorded in each row. For example, TextEntries (for objects)
#   may record restrictions, provenance notes, creator biographical
#   notes, or textual exhibition history. AltNums (for
#   references/citations) may be ISBNs, call numbers, etc.
#
# For such tables, we need type cleanup and treatment indication
#   routine. This will happen at the "for-table" level, since values
#   for Objects vs. Constituents, etc. will need to be handled
#   separately.
#
# If you wish to trigger inclusion of this handling for a
#   MultiTableMergeable config module, define a `type_field` setting
#   or method in the config module prior to extending MultiTableMergeable.
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
#
# #### `unreportable_for_tables_ok`
#
# If you are being nagged/warned about "unreportable for tables" needing
#   `record_num_merge_config` settings configured, adding the for table name to
#   this setting will suppress those warnings.
#
# #### `for_table_lookup_on_field`
#
# Used in {ForTable}.
#
# Sets the field used as `lookup_on` value in the for-table job registry
#   entries. That is, when target table Objects uses `alt_nums_for__objects` as
#   a lookup, what field in the latter will match `:objectid`?
#
# By default, this is `:recordid`, but you may override it before extending.
#
# ### Auto-configurable settings
#
# These are expected to vary per project. The settings below will be
#   defined with blank default values on the extending module, and
#   should be overridden in client configs. These are auto-configured
#   settings, which means you can use Utils::InitialConfigDeriver to
#   get output you can copy/paste into the client config, based on
#   what's actually in their data.
#
# #### `target_tables`
#
# The list of tables the multi-table-mergeable table's data will be
#   merged into. Depending on how a client has entered data into TMS,
#   target tables will differ.
module Kiba
  module Tms
    module Mixins
      module MultiTableMergeable
        include Tms::Mixins::ForTable
        include Tms::Mixins::ReportableForTable
        def self.extended(mod)
          set_for_table_source_job_key_setting(mod)
          set_split_on_column_setting(mod)
          set_target_tables_setting(mod)
          set_unreportable_for_tables_ok_setting(mod)
          set_checkable(mod)
        end

        def for?(table)
          target_tables.any?(table)
        end

        # override manually in module after extending
        def auto_generate_target_tables
          true
        end

        # METHODS USED FOR RUNNING CHECKS
        #
        # Reports if there is a target_table with no matching setting
        #   defined in the config
        def check_needed_table_transform_settings
          needed = target_transform_settings_expected.reject do |transform|
            respond_to?(transform)
          end
          return nil if needed.empty?

          "#{name}: add config settings: #{needed.join(", ")}"
        end

        # Reports if a defined for-target-table transform setting (e.g. a
        #   `for_*_prepper` method/setting) defined in the config, but no
        #   value (an actual transform class or :no_xform) has been assigned
        #   to the setting. These indicate there may be more work to be
        #   done.
        def check_undefined_table_transforms
          undefined =
            target_transform_settings - target_transform_settings_handled
          return nil if undefined.empty?

          "#{name}: no transforms defined for: #{undefined.join(", ")}"
        end

        def check_unreportable_for_tables
          tables = unreportable_for_tables
          return nil if tables.empty?

          "#{name}: tables needing :record_num_merge_config defined: "\
            "#{tables.join(", ")}"
        end

        # List target tables that do not respond to
        #   `:record_num_merge_config`, that are not listed in the
        #   :unreportable_for_tables_ok setting
        #
        # @return [Array<String>] of table names, e.g. "Objects"
        def unreportable_for_tables
          target_tables.map { |t| Object.const_get("Tms::#{t}") }
            .reject { |t| t.respond_to?(:record_num_merge_config) }
            .map(&:to_s)
            .map { |val| val.delete_prefix("Kiba::Tms::") }
            .sort - unreportable_for_tables_ok
        end

        # All `for_*_prepper` methods/settings defined on extending module
        #
        # @return [Array<Symbol>]
        def target_transform_settings
          settings
            .map(&:to_s)
            .select { |meth| meth.match?(/^for_.*_prepper$/) }
            .map(&:to_sym)
        end
        private :target_transform_settings

        # `for_*_prepper` methods/settings that are explicitly defined with
        #   an xform class. This list is passed to job definitions to
        #   configure what xforms each job will run.
        #
        # @return [Array<Symbol>]
        def target_transform_settings_defined_with_xform
          target_transform_settings.reject do |setting|
            val = config.values[setting]
            val.nil? || val == :no_xform
          end
        end
        private :target_transform_settings_defined_with_xform

        # Generates a list of expected `for_*_prepper` method/setting
        #   names---one for each target table
        #
        # @return [Array<Symbol>]
        def target_transform_settings_expected
          target_tables.map do |target|
            tobj = Tms::Table::Obj.new(target)
            "for_#{tobj.filekey}_prepper".to_sym
          end
        end
        private :target_transform_settings_expected

        # `for_*_prepper` methods/settings defined with actual transform
        #   classes or :no_xform placeholders to indicate we have analyzed
        #   the data and found no need for a specific transform. These
        #   should no longer be flagged as needing attention/work.
        #
        # @return [Array<Symbol>]
        def target_transform_settings_handled
          target_transform_settings.reject do |setting|
            config.values[setting].nil?
          end
        end
        private :target_transform_settings_handled

        # METHODS FOR EXTENDING
        def self.set_checkable(mod)
          if mod.respond_to?(:checkable)
            checkable_as_needed(mod)
          else
            checkable_from_scratch(mod)
          end
        end
        private_class_method :set_checkable

        def self.set_for_table_source_job_key_setting(mod)
          return if mod.respond_to?(:for_table_source_job_key)

          str = <<~CFG
            setting :for_table_source_job_key,
            default: :prep__#{mod.filekey},
            reader: true
          CFG
          mod.module_eval(str)
        end
        private_class_method :set_for_table_source_job_key_setting

        def self.set_split_on_column_setting(mod)
          return if mod.respond_to?(:split_on_column)

          mod.module_eval(
            "setting :split_on_column, default: :tablename, reader: true",
            __FILE__,
            __LINE__ - 2
          )
        end
        private_class_method :set_split_on_column_setting

        def self.set_target_tables_setting(mod)
          return if mod.respond_to?(:target_tables)

          mod.module_eval(
            "setting :target_tables, default: [], reader: true",
            __FILE__,
            __LINE__ - 2
          )
        end
        private_class_method :set_target_tables_setting

        def self.set_unreportable_for_tables_ok_setting(mod)
          return if mod.respond_to?(:unreportable_for_tables_ok)

          mod.module_eval(
            "setting :unreportable_for_tables_ok, default: [], reader: true",
            __FILE__,
            __LINE__ - 2
          )
        end
        private_class_method :set_unreportable_for_tables_ok_setting

        # METHODS USED BY METHODS USED FOR EXTENDING
        def self.checkable_as_needed(mod)
          existing = mod.checkable.dup
          checkable_from_scratch(mod)
          combined = mod.checkable.merge(existing)
          mod.config.checkable = combined
        end
        private_class_method :checkable_as_needed

        def self.checkable_from_scratch(mod)
          code = %(
          setting :checkable,
            default:              {
              needed_table_transform_settings: Proc.new{
                check_needed_table_transform_settings
              },
              undefined_table_transforms: Proc.new{
                check_undefined_table_transforms
              },
              nonreportable_for_tables: Proc.new{
                check_unreportable_for_tables
              }
            },
            reader: true
          ).tr("\n", " ")

          mod.module_eval(code)
        end
        private_class_method :checkable_from_scratch
      end
    end
  end
end
