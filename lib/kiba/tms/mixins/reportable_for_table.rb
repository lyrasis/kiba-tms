# frozen_string_literal: true

module Kiba
  module Tms
    module Mixins
      # Methods used by {MultiTableMergeable} to auto-register
      #   reportable-for-table jobs
      #
      # Reportable-for-table jobs merge human-readable record id numbers
      #   into the regular mergeable for-table. These jobs are registered
      #   only for target tables that have a :record_num_merge_config
      #   config setting defined. Example:
      #
      #  setting :record_num_merge_config,
      #    default: {
      #      sourcejob: :objects__number_lookup,
      #      fieldmap: {targetrecord: :objectnumber}
      #  }, reader: true
      #
      module ReportableForTable
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
            creator: {callee:
                        Tms::Jobs::MultiTableMergeable::ReportableForTable,
                      args: {
                        source: source,
                        dest: dest,
                        config: config
                      }},
            tags: [ns.to_sym]
          }
        end
        private :reportable_job_hash
      end
    end
  end
end
