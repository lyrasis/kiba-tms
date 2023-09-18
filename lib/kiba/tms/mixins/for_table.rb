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
        private :define_for_table_module

        # @return [String]
        def for_table_module_name(jobkey)
          jobkey.to_s
            .split(/_+/)
            .map(&:capitalize)
            .join
        end
        private :for_table_module_name

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
              targetxform = mod.send(:target_xform, targetobj)
              params = [ns_name, targetobj, field, targetxform]
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

        # @return [Array<Class>] prepper transform class(es) for the for-table
        def target_xform(targetobj)
          sym = "for_#{targetobj.filekey}_prepper".to_sym
          return [send(sym)].flatten if respond_to?(sym) && !send(sym).nil?

          []
        end
        private :target_xform

        # Builds a registry entry hash for a reportable-for-job
        #
        # @param ns_name [String] e.g. "alt_nums_for"
        # @param targetobj [Tms::Table::Obj]
        # @param field [Symbol] e.g. "alt_nums_reportable_for__objects"
        # @param xforms [Array<Class>]
        # @return [Hash]
        def target_job_hash(ns_name, targetobj, field, xforms)
          key = targetobj.filekey
          {
            path: File.join(Tms.datadir, "working", "#{ns_name}_#{key}.csv"),
            creator: {callee: Tms::Jobs::MultiTableMergeable::ForTable,
                      args: {
                        source: for_table_source_job_key,
                        dest: "#{ns_name}__#{key}".to_sym,
                        targettable: targetobj.tablename,
                        field: field,
                        xforms: xforms
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
