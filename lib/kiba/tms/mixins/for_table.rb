# frozen_string_literal: true

module Kiba
  module Tms
    module Mixins
      # Methods used by {MultiTableMergeable} to auto-register
      #   for-table jobs
      #
      # For-table jobs split up the overall multi-table-mergeable table (e.g.
      #   AltNums) into separate tables for each mergeable target table (e.g.
      #   alt_nums_for__objects, alt_nums_for__constituents, etc.)
      #
      # In client-specific projects, the following settings may be set
      #   per-for-table, **in the project's dependent config section**
      #   (i.e. after `Tms.meta_config` has been run, which is what
      #   causes for tables to be defined. You can't define settings
      #   on a module that hasn't yet been defined in the
      #   application!)
      #
      # - delete_fields [Array<Symbol>] - list fields to be deleted
      #   from the specific ForTable that should not be deleted from
      #   other ForTables from the same source table
      # - empty_fields [Same format as used in autoconfig of main
      #   tables] Used to track/flag when a previously empty field
      #   (perhaps not handled) becomes non-empty after a data update,
      #   and thus may need attention
      # - prepper_xforms [nil, Array<#process>] - list of job transforms to
      #   be applied after rows for target table are isolated, in the
      #   job that creates the for-table. Can be one or more classes
      #   meeting implementation criteria for a Kiba transform
      # - merger_xforms [nil, Array<#process>] - list of job transforms used
      #   in job where target table is the source, to merge for_table data into
      #   target table. Can be one or more classes meeting implementation
      #   criteria for a Kiba transform.
      # - merge_lookup [Symbol] - full registry entry job key for the
      #   table that will be used as lookup source for merging this
      #   ForTable data into target table. By default, this is set to
      #   the reportable_for type_cleanup_merge job for this ForTable.
      #   Only override this if specific client project needs to
      #   further modify the ForTable data after empty type cleanup
      #   and type cleanup have been applied. Typically this will look
      #   like creating a custom job in the client project and using
      #   that job's key in this setting.
      # - treatment_mergers [Hash{Symbol=>Class}] Override default
      #   treatment mergers or define custom treatments (and their
      #   associated transforms) in client-specific project config. Is
      #   merged into `base_treatment_mergers`. See that setting's
      #   documentation below for more info.
      #
      # The following settings are also created for internal use. It is
      #   recommended that you NOT override them:
      #
      # - source_job_key - The registry entry job key that creates the
      #   given ForTable to meet criteria for extending `Tableable` on
      #   a non-TMS-base-table.
      # - base_treatment_mergers [Hash{Symbol=>Class}] Indicates
      #   default transform class for each treatment. Automatically
      #   derived based on treatment mergers defined in
      #   Kiba::Tms::Transforms::{parentmodule}. To be detected,
      #   treatment merger classes must be named following the
      #   pattern: For{TargetTable}TreatmentMerger{treatment
      #   camelcased}. For example:
      #   `Tms::Transforms::AltNums::ForObjectsTreatmentMergerOtherNumber`.
      #   To provide custom transformation for a default treatment,
      #   the specific treatment can be overridden in client-specific
      #   `treatment_mergers` setting. That setting is merged into
      #   this base setting, so keys defined overwrite the base
      #   definition. Custom/new treatments can also be defined in
      #   `treatment_mergers`.
      module ForTable
        # Called as part of Tms.meta_config setup
        def define_for_table_modules
          puts "Defining `for_table` modules for #{name}" if Tms.verbose?

          target_tables.each do |target|
            puts "Defining `for_table` module for #{target}" if Tms.debug?
            define_for_table_module(target)
          end
        end

        # Called by {Kiba::Tms::Utils::ForTableJobRegistrar} at application load
        #
        # @param field [Symbol] name of field on which for_tables will be
        #   split. Defaults to: `:tablename`.
        def register_for_table_jobs(field = split_on_column)
          key = filekey
          return unless key

          ns = build_registry_namespace(
            "#{key}_for",
            target_tables,
            field
          )

          Tms.registry.import(ns)
        end

        # rubocop:disable Layout/LineLength
        def define_for_table_module(target)
          targetobj = Tms::Table::Obj.new(target)
          target = targetobj.tablename
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

              setting :prepper_xforms,
                default: #{default_xforms(target, "Prepper")},
                reader: true,
                constructor: ->(default) do
                  default == "nil" ? nil : default
                end
              setting :merger_xforms,
                default: #{default_xforms(target, "Merger")},
                reader: true,
                constructor: ->(default) do
                  default == "nil" ? nil : default
                end
              setting :merge_lookup,
                default: :#{table.filekey}_reportable_for__#{targetobj.filekey}_type_cleanup_merge,
                reader: true
              setting :base_treatment_mergers,
                default: #{set_base_treatment_mergers(target)},
                reader: true
              setting :treatment_mergers,
                default: {},
                reader: true,
                constructor: ->(default) do
                  base_treatment_mergers.merge(default)
                end
              def used?
                true
              end
            end
          MODDEF
          Tms.module_eval(moddef, __FILE__, __LINE__)
        end
        private :define_for_table_module
        # rubocop:enable Layout/LineLength

        def xforms_namespace
          modname = name.to_s.split("::").last
          return nil unless Tms::Transforms.constants
            .map(&:to_s)
            .include?(modname)

          Tms::Transforms.const_get(modname)
        end
        private :xforms_namespace

        def default_xforms(targetname, type)
          modxforms = xforms_namespace
          return "nil" unless modxforms

          xformname = ["For", targetname, type].join
          xform = modxforms.constants.map(&:to_s).include?(xformname)
          return "nil" unless xform

          [modxforms.const_get(xformname)]
        end
        private :default_xforms

        def set_base_treatment_mergers(target)
          modxforms = xforms_namespace
          return {} unless modxforms

          xform_prefix = "For#{target}TreatmentMerger"
          mergers = modxforms.constants
            .map(&:to_s)
            .select { |xform| xform.start_with?(xform_prefix) }
          return {} if mergers.empty?

          setup_treatment_mergers(modxforms, xform_prefix, mergers)
        end
        private :set_base_treatment_mergers

        def setup_treatment_mergers(modxforms, xform_prefix, mergers)
          mergers.map { |merger| setup_treatment_merger(xform_prefix, merger) }
            .to_h
            .transform_values { |val| modxforms.const_get(val) }
        end
        private :setup_treatment_mergers

        def setup_treatment_merger(xform_prefix, merger)
          treatment = merger.delete_prefix(xform_prefix)
            .gsub(/([A-Z])/, '_\1')
            .downcase
            .delete_prefix("_")
            .to_sym
          [treatment, merger]
        end
        private :setup_treatment_merger

        # @return [String]
        def for_table_module_name(jobkey)
          jobkey.to_s
            .split(/_+/)
            .map(&:capitalize)
            .join
        end
        private :for_table_module_name

        # @return [Module]
        def for_table_module(jobkey)
          Tms.const_get(for_table_module_name(jobkey))
        end
        private :for_table_module

        # Defines a registry namespace (e.g. alt_nums_for).
        #   Within it, registers a job for each for-table (e.g.
        #   alt_nums_for__objects)
        #
        # @param ns_name [String] e.g. "alt_nums_for"
        # @param targets [Array<String>] target tables
        # @param field [Symbol] to split on
        def build_registry_namespace(ns_name, targets, field)
          bind = binding
          Dry::Container::Namespace.new(ns_name) do
            mod = bind.receiver
            targets.each do |target|
              targetobj = Tms::Table::Obj.new(target)
              params = [ns_name, targetobj, field]
              register targetobj.filekey, mod.send(
                :target_job_hash, *params
              )
              if Tms.debug?
                puts "Register job: #{ns_name}__#{targetobj.filekey}"
              end
            end
          end
        end
        private :build_registry_namespace

        # Builds a registry entry hash for a reportable-for-job
        #
        # @param ns_name [String] e.g. "alt_nums_for"
        # @param targetobj [Tms::Table::Obj]
        # @param field [Symbol] e.g. :tablename
        # @return [Hash]
        def target_job_hash(ns_name, targetobj, field)
          key = targetobj.filekey
          for_table_key = "#{ns_name}__#{key}".to_sym
          for_table_mod = for_table_module(for_table_key)
          {
            path: File.join(Tms.datadir, "working", "#{ns_name}_#{key}.csv"),
            creator: {callee: Tms::Jobs::MultiTableMergeable::ForTable,
                      args: {
                        source: for_table_source_job_key,
                        dest: for_table_key,
                        for_table_mod: for_table_mod,
                        targettable: targetobj.tablename,
                        field: field
                      }},
            tags: for_table_tags(ns_name, targetobj),
            lookup_on: lookup_on_field
          }
        end

        # @return [Array<Symbol>]
        def for_table_tags(ns_name, targetobj)
          [
            ns_name.to_s.delete_suffix("_for").to_sym,
            targetobj.filekey,
            :for_table
          ]
        end
        private :for_table_tags

        # @return [Symbol]
        def lookup_on_field
          return for_table_lookup_on_field if respond_to?(
            :for_table_lookup_on_field
          )

          :recordid
        end
        private :lookup_on_field
      end
    end
  end
end
