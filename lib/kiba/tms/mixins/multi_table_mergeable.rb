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
#   into tables for each target; and (b) merge human-readable ids from
#   the main target tables into the mergable "for" tables. (Example:
#   merge objectnumber values into alt_nums_for__objects)
#
# ## Implementation details
#
# Modules mixing this in must:
#
# - `extend Tms::Mixins::MultiTableMergeable`
#
# Assumes the table to be split up into individual target tables is
#   produced by :prep__job_key
#
# **IF NOT**, manually specify in :for_table_source_job_key setting
#   in your config module before extending MultiTableMergeable
module Kiba::Tms::Mixins::MultiTableMergeable
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

  # List target tables that do not respond to `:record_num_merge_config`, that
  #   are not listed in the :unreportable_for_tables_ok setting
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

  # Generates a list of expected `for_*_prepper` method/setting names---one for
  #   each target table
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

  # METHODS USED FOR AUTO-REGISTERING REPORTABLE-FOR-TABLE JOBS
  #
  # Reportable-for-table jobs merge human-readable record id numbers
  #   into the regular mergeable for-table. These jobs are registered
  #   only for target tables that have a :record_num_merge_config
  #   config setting defined. Example:
  #
  #  setting :record_num_merge_config,
  #    default: {
  #      sourcejob: :objects__number_lookup,
  #      numberfield: :objectnumber
  #  }, reader: true
  #

  # Called by {Kiba::Tms::Utils::ForTableJobRegistrar} at application load
  def register_reportable_for_table_jobs
    return if reportable_for_table_configs.empty?

    ns = build_reportable_registry_namespace(
      source_ns: "#{filekey}_for",
      ns: "#{filekey}_reportable_for",
      config: reportable_for_table_configs
    )
    Tms.registry.import(ns)
  end

  # @return [Hash{Constant=>Hash}] of reportable-for-tables, i.e.
  #   target tables whose configs define the :record_num_merge_config
  #   setting. Hash key is the target table config Constant (e.g.
  #   Kiba::Tms::Objects), and value is the :record_num_merge_config
  #   setting value
  def reportable_for_table_configs
    target_tables.map { |t| Object.const_get("Tms::#{t}") }
      .select { |t| t.respond_to?(:record_num_merge_config) }
      .map { |t| [t, t.send(:record_num_merge_config)] }
      .to_h
  end
  private :reportable_for_table_configs

  # Defines a registry namespace (e.g. alt_nums_reportable_for).
  #   Within it, registers a job for each reportable-for-table (e.g.
  #   alt_nums_reportable_for__objects)
  #
  # @param source_ns [String] e.g. "alt_nums_for"
  # @param ns [String] e.g. "alt_nums_reportable_for"
  # @param config [Hash{Constant=>Hash}]
  def build_reportable_registry_namespace(source_ns:, ns:, config:)
    bind = binding
    Dry::Container::Namespace.new(ns) do
      mod = bind.receiver

      config.each do |const, cfg|
        filekey = const.filekey

        params = {
          ns: ns,
          source: "#{source_ns}__#{filekey}".to_sym,
          dest: "#{ns}__#{filekey}".to_sym,
          config: cfg
        }
        register filekey, mod.send(:reportable_job_hash, **params)
      end
    end
  end
  private :build_reportable_registry_namespace

  # Builds a registry entry hash for a reportable-for-job
  #
  # @param ns [String] e.g. "alt_nums_reportable_for"
  # @param source [Symbol] e.g. "alt_nums_for__objects"
  # @param dest [Symbol] e.g. "alt_nums_reportable_for__objects"
  # @param config [Hash{Constant=>Hash}]
  # @return [Hash]
  def reportable_job_hash(ns:, source:, dest:, config:)
    {
      path: File.join(Tms.datadir, "working", "#{dest}.csv"),
      creator: {callee: Tms::Jobs::MultiTableMergeable::ReportableForTable,
                args: {
                  source: source,
                  dest: dest,
                  config: config
                }},
      tags: [ns.to_sym]
    }
  end
  private :reportable_job_hash

  # METHODS USED FOR AUTO-REGISTERING FOR-TABLE JOBS

  # @param field [Symbol] name of field on which for_tables will be
  #   split. By default this is `:tablename`. To override, define
  #   `split_on_column` setting prior to extending this module. See
  #   {Kiba::Tms::ConRefs} for an example.
  def register_for_table_jobs(field = split_on_column)
    key = filekey
    return unless key

    ns = build_registry_namespace(
      "#{key}_for",
      target_tables,
      field,
      target_transform_settings_defined_with_xform
    )
    Tms.registry.import(ns)
  end

  def build_registry_namespace(ns_name, targets, field, xforms)
    bind = binding
    Dry::Container::Namespace.new(ns_name) do
      mod = bind.receiver
      targets.each do |target|
        targetobj = Tms::Table::Obj.new(target)
        targetxform = mod.target_xform(xforms, targetobj)
        params = [mod, ns_name, targetobj, field, targetxform]
        register targetobj.filekey, mod.send(
          :target_job_hash, *params
        )
      end
    end
  end

  def target_xform(xforms, targetobj)
    sym = "for_#{targetobj.filekey}_prepper".to_sym
    if xforms.any?(sym)
      [send(sym)].flatten
    else
      []
    end
  end

  def for_table_tags(ns_name, targetobj)
    [
      ns_name.to_s.delete_suffix("_for").to_sym,
      targetobj.filekey,
      :for_table
    ]
  end

  def target_job_hash(mod, ns_name, targetobj, field, xforms)
    key = targetobj.filekey
    {
      path: File.join(Tms.datadir, "working", "#{ns_name}_#{key}.csv"),
      creator: {callee: Tms::Jobs::MultiTableMergeable::ForTable,
                args: {
                  source: mod.for_table_source_job_key,
                  dest: "#{ns_name}__#{key}".to_sym,
                  targettable: targetobj.tablename,
                  field: field,
                  xforms: xforms
                }},
      tags: for_table_tags(ns_name, targetobj),
      lookup_on: mod.lookup_on_field
    }
  end

  def lookup_on_field
    return for_table_lookup_on_field if respond_to?(
      :for_table_lookup_on_field
    )

    :recordid
  end

  # METHODS USED FOR AUTO-CONFIGURING FOR-TABLES
  def for_table_module_name(jobkey)
    jobkey.to_s
      .split(/_+/)
      .map(&:capitalize)
      .join
  end

  def define_for_table_module(target)
    targetobj = Tms::Table::Obj.new(target)
    jobkey = "#{table.filekey}_for__#{targetobj.filekey}".to_sym

    moddef = <<~MODDEF
      module #{for_table_module_name(jobkey)}
        extend Dry::Configurable
        module_function

        # Indicates what job output to use as the base for
        #   non-TMS-table-sourced modules
        setting :source_job_key, default: :#{jobkey}, reader: true
        setting :delete_fields, default: [], reader: true
        setting :empty_fields, default: {}, reader: true
        extend Tms::Mixins::Tableable

        def used?
          true
        end
      end
    MODDEF
    Tms.module_eval(moddef)
  end

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
