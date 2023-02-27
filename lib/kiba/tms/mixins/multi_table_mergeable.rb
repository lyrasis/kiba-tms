# frozen_string_literal: true

module Kiba
  module Tms
    module Mixins
      # Mixin module
      #
      # ## Implementation
      #
      # Assumes the table to be split up into individual target tables is
      #   produced by :prep__job_key
      #
      # **IF NOT**, manually specify in :for_table_source_job_key setting
      #   in your config module before extending MultiTableMergeable
      module MultiTableMergeable
        def self.extended(mod)
          self.set_for_table_source_job_key_setting(mod)
          self.set_split_on_column_setting(mod)
          self.set_target_tables_setting(mod)
          self.set_checkable(mod)
        end

        def is_multi_table_mergeable?
          true
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
        # Reports if there is a target_table with no matching setting defined
        #   in the config
        def check_needed_table_transform_settings
          needed = target_transform_settings_expected.reject do |transform|
            self.respond_to?(transform)
          end
          return nil if needed.empty?

          "#{self.name}: add config settings: #{needed.join(', ')}"
        end

        # Reports if a defined for-target-table transform setting defined in the
        #   config, but no value (an actual transform class or :no_xform) has
        #   been assigned to the setting. These indicate there may be more work
        #   to be done.
        def check_undefined_table_transforms
          undefined =
            target_transform_settings - target_transform_settings_handled
          return nil if undefined.empty?

          "#{self.name}: no transforms defined for: #{undefined.join(', ')}"
        end

        def target_transform_settings
          self.settings
            .map(&:to_s)
            .select{ |meth| meth.match?(/^for_.*_prepper$/) }
            .map(&:to_sym)
        end

        # These are defined with actual transform classes
        def target_transform_settings_defined
          target_transform_settings.reject do |setting|
            val = config.values[setting]
            val.nil? || val == :no_xform
          end
        end

        def target_transform_settings_expected
          target_tables.map do |target|
            tobj = Tms::Table::Obj.new(target)
            "for_#{tobj.filekey}_prepper".to_sym
          end
        end

        # These are defined with actual transform classes or :no_xform
        #   placeholders to indicate we have analyzed the data and found no need
        #   for a specific transform
        def target_transform_settings_handled
          target_transform_settings.reject do |setting|
            config.values[setting].nil?
          end
        end

        # METHODS USED FOR AUTO-REGISTERING REPORTABLE-FOR-TABLE JOBS
        #
        # Reportable-for-table jobs merge human-readable record id numbers
        #   into the regular mergeable for-table. These jobs are registered
        #   only for target tables that have a :record_num_merge_config config
        #   setting defined. Example:
        #
        #  setting :record_num_merge_config,
        #    default: {
        #      sourcejob: :objects__number_lookup,
        #      numberfield: :objectnumber
        #  }, reader: true
        # @return [Hash] of reportable-for-tables, i.e. target tables whose
        #   configs define the :record_num_merge_config setting. Hash key
        #   is the target table config Constant, and value is the
        #   :record_num_merge_config setting value
        def reportable_for_tables
          target_tables.map{ |t| Object.const_get("Tms::#{t}") }
            .select{ |t| t.respond_to?(:record_num_merge_config) }
            .map{ |t| [t, t.send(:record_num_merge_config)] }
            .to_h
        end

        def register_reportable_for_table_jobs
          return if reportable_for_tables.empty?

          ns = build_reportable_registry_namespace(
            source_ns: "#{filekey}_for",
            ns: "#{filekey}_reportable_for",
            config: reportable_for_tables
          )
          Tms.registry.import(ns)
        end

        def build_reportable_registry_namespace(source_ns:, ns:, config:)
          bind = binding
          Dry::Container::Namespace.new(ns) do
            mod = bind.receiver
            config.each do |const, cfg|
              filekey = const.filekey
              params = {
                source: "#{source_ns}__#{filekey}".to_sym,
                dest: "#{ns}__#{filekey}".to_sym,
                config: cfg
              }
              register filekey, mod.send(:reportable_job_hash, **params)
            end
          end
        end

        def reportable_job_hash(source:, dest:, config:)
          {
            path: File.join(Tms.datadir, 'working', "#{dest}.csv"),
            creator: {callee: Tms::Jobs::ReportableForTable,
                      args: {
                        source: source,
                        dest: dest,
                        config: config
                      }
                     }
          }
        end

        # METHODS USED FOR AUTO-REGISTERING FOR-TABLE JOBS
        def register_per_table_jobs(field = split_on_column)
          key = filekey
          return unless key

          ns = build_registry_namespace(
            "#{key}_for",
            target_tables,
            field,
            target_transform_settings_defined
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
              register targetobj.filekey, mod.send(:target_job_hash, *params)
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

        def target_job_hash(mod, ns_name, targetobj, field, xforms)
          key = targetobj.filekey
          tags = [ns_name, key].map(&:to_s)
            .map{ |val| val.gsub('_', '') }
            .map(&:to_sym)
          tabletag = tags.shift
          [tabletag.to_s.delete_suffix('_for').to_sym, :for_table].each do |tag|
            tags << tag
          end

          {
            path: File.join(Tms.datadir, 'working', "#{ns_name}_#{key}.csv"),
            creator: {callee: Tms::Jobs::ForTable,
                      args: {
                        source: mod.for_table_source_job_key,
                        dest: "#{ns_name}__#{key}".to_sym,
                        targettable: targetobj.tablename,
                        field: field,
                        xforms: xforms
                      }
                     },
            tags: tags,
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
            self.checkable_as_needed(mod)
          else
            self.checkable_from_scratch(mod)
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
            'setting :split_on_column, default: :tablename, reader: true'
          )
        end
        private_class_method :set_split_on_column_setting

        def self.set_target_tables_setting(mod)
          return if mod.respond_to?(:target_tables)

          mod.module_eval('setting :target_tables, default: [], reader: true')
        end
        private_class_method :set_target_tables_setting

        # METHODS USED BY METHODS USED FOR EXTENDING
        def self.checkable_as_needed(mod)
          existing = mod.checkable.dup
          self.checkable_from_scratch(mod)
          combined = mod.checkable.merge(existing)
          mod.config.checkable = combined
        end
        private_class_method :checkable_as_needed

        def self.checkable_from_scratch(mod)
          code = %{
          setting :checkable,
            default:              {
              needed_table_transform_settings: Proc.new{
                check_needed_table_transform_settings
              },
              undefined_table_transforms: Proc.new{
                check_undefined_table_transforms
              }
            },
            reader: true
          }.gsub("\n", ' ')

          mod.module_eval(code)
        end
        private_class_method :checkable_from_scratch

      end
    end
  end
end
