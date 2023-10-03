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
          return if target_table_configs.empty?

          ns = build_reportable_registry_namespace(
            source_ns: "#{filekey}_for",
            ns: "#{filekey}_reportable_for",
            configs: target_table_configs
          )
          Tms.registry.import(ns)
        end

        # Whether there are human readable id numbers in reportable for table
        #   job (and thus extra fields to deal with in subsequent jobs)
        #
        # @param target [Module]
        # @return [Boolean]
        def target_ids_mergeable?(target)
          true if target.respond_to?(:record_num_merge_config) &&
            target.record_num_merge_config
        end

        # Defines a registry namespace (e.g. alt_nums_reportable_for).
        #   Within it, registers a job for each reportable-for-table (e.g.
        #   alt_nums_reportable_for__objects)
        #
        # @param source_ns [String] e.g. "alt_nums_for"
        # @param ns [String] e.g. "alt_nums_reportable_for"
        # @param config [Hash{Constant=>Hash}]
        def build_reportable_registry_namespace(source_ns:, ns:, configs:)
          bind = binding
          Dry::Container::Namespace.new(ns) do
            mod = bind.receiver

            configs.each do |config|
              filekey = config.filekey
              for_table_job = "#{source_ns}__#{filekey}".to_sym
              reportable_job = "#{ns}__#{filekey}".to_sym

              tags = [source_ns.delete_suffix("_for").to_sym,
                filekey, :reportable_for_table]

              register filekey, mod.send(:reportable_job_hash,
                source: for_table_job,
                dest: reportable_job,
                config: config,
                tags: tags)
              puts "Register job: #{reportable_job}" if Tms.debug?

              # rubocop:disable Layout/LineLength
              empty_type_cleanup_merge = "#{filekey}_empty_type_cleanup_merge".to_sym
              empty_type_cleanup_merge_job = "#{ns}__#{empty_type_cleanup_merge}".to_sym
              register empty_type_cleanup_merge, mod.send(
                :empty_type_cleanup_merge_job_hash,
                source: reportable_job,
                dest: empty_type_cleanup_merge_job,
                lkup: "#{source_ns}_#{filekey}_empty_type_cleanup__final".to_sym,
                mod: mod,
                tags: [tags, :empty_type_cleanup].flatten
              )
              puts "Register job: #{cleanup_merge_job}" if Tms.debug?
              # rubocop:enable Layout/LineLength

              type_cleanup_merge = "#{filekey}_type_cleanup_merge".to_sym
              type_cleanup_merge_job = "#{ns}__#{type_cleanup_merge}".to_sym
              register type_cleanup_merge, mod.send(
                :type_cleanup_merge_job_hash,
                source: empty_type_cleanup_merge_job,
                dest: type_cleanup_merge_job,
                lkup: "#{source_ns}_#{filekey}_type_cleanup__final".to_sym,
                mergemod: mod,
                targetmod: config,
                tags: [tags, :type_cleanup].flatten
              )
              puts "Register job: #{cleanup_merge_job}" if Tms.debug?

              next unless mod.respond_to?(:type_field) &&
                mod.respond_to?(:mergeable_value_field)

              type_occs = "#{filekey}_type_occs".to_sym
              type_occs_job = "#{ns}__#{type_occs}".to_sym
              register type_occs, mod.send(:type_occs_job_hash,
                source: empty_type_cleanup_merge_job,
                dest: type_occs_job,
                mergemod: mod,
                targetmod: config,
                tags: tags)
              puts "Register job: #{type_occs_job}" if Tms.debug?

              no_type = "#{filekey}_no_type".to_sym
              no_type_job = "#{ns}__#{no_type}".to_sym
              register no_type, mod.send(:no_type_job_hash,
                source: reportable_job,
                dest: no_type_job,
                mod: mod,
                tags: [tags, :empty_types, :reports].flatten)
              puts "Register job: #{no_type_job}" if Tms.debug?
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
        def reportable_job_hash(source:, dest:, config:, tags:)
          {
            path: File.join(Tms.datadir, "working", "#{dest}.csv"),
            creator: {callee:
                      Tms::Jobs::MultiTableMergeable::ReportableForTable,
                      args: {
                        source: source,
                        dest: dest,
                        config: config
                      }},
            tags: tags,
            lookup_on: :lookupkey,
            desc: "If target table is configured for id merge, merges human "\
              "readable id for target record into each mergeable row. "\
              "Otherwise passes all rows through with no changes."
          }
        end
        private :reportable_job_hash

        def type_occs_job_hash(source:, dest:, mergemod:, targetmod:, tags:)
          {
            path: File.join(Tms.datadir, "working", "#{dest}.csv"),
            creator: {callee:
                      Tms::Jobs::MultiTableMergeable::TypeOccs,
                      args: {
                        source: source,
                        dest: dest,
                        mergemod: mergemod,
                        targetmod: targetmod
                      }},
            tags: [tags, :reports].flatten,
            desc: "Deduplicates on type field value and merges in occurrence "\
              "count (number of times that type assigned to a value); example "\
              "target record ids and example mergeable values using the type, "\
              "and, optionally, counts of how many occurrences of each type "\
              "have given fields populated (# of type occs with remarks or "\
              "dates, typically. Used as input for other reports and type "\
              "cleanup job processes"
          }
        end
        private :type_occs_job_hash

        def no_type_job_hash(source:, dest:, mod:, tags:)
          {
            path: File.join(Tms.datadir, "reports", "#{dest}.csv"),
            creator: {callee:
                      Tms::Jobs::MultiTableMergeable::NoType,
                      args: {
                        source: source,
                        dest: dest,
                        mod: mod
                      }},
            tags: [tags, :reports].flatten,
            desc: "Report of mergeable values with no type value. If client "\
              "desires, can be used as base for Provide Type Cleanup"
          }
        end
        private :type_occs_job_hash

        def empty_type_cleanup_merge_job_hash(source:, dest:, lkup:, tags:,
          mod:)
          {
            path: File.join(Tms.datadir, "working", "#{dest}.csv"),
            creator: {callee:
                      Tms::Jobs::MultiTableMergeable::EmptyTypeCleanupMerge,
                      args: {
                        source: source,
                        dest: dest,
                        lkup: lkup,
                        mod: mod
                      }},
            tags: [tags, :for_table_empty_type, :cleanup].flatten,
            lookup_on: :lookupkey,
            desc: "Merges client-cleanup provided type values and notes into "\
              "reportable for table. If no cleanup is needed or done, the "\
              "original reportable for table is passed through"
          }
        end
        private :empty_type_cleanup_merge_job_hash

        def type_cleanup_merge_job_hash(source:, dest:, lkup:, tags:, mergemod:,
          targetmod:)
          {
            path: File.join(Tms.datadir, "working", "#{dest}.csv"),
            creator: {callee:
                      Tms::Jobs::MultiTableMergeable::TypeCleanupMerge,
                      args: {
                        source: source,
                        dest: dest,
                        lkup: lkup,
                        mergemod: mergemod,
                        targetmod: targetmod
                      }},
            tags: tags,
            desc: "Merges cleaned up types and assigned treatments into "\
              "reportable for table. If no cleanup was done, passes the "\
              "source table through."
          }
        end
        private :type_cleanup_merge_job_hash
      end
    end
  end
end
