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
          self.set_split_on_column_setting(mod)
          self.set_target_tables_setting(mod)
        end

        def is_multi_table_mergeable?
          true
        end

        def for?(table)
          target_tables.any?(table)
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
            .select{ |meth| meth.match?(/^for_.*_transform$/) }
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
            "for_#{tobj.filekey}_transform".to_sym
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
          sym = "for_#{targetobj.filekey}_transform".to_sym
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
                        source: mod.for_table_source,
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

        def for_table_source
          return for_table_source_job_key if respond_to?(
            :for_table_source_job_key
          )

          "prep__#{filekey}".to_sym
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
      end
    end
  end
end
