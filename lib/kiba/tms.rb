# frozen_string_literal: true

require "kiba/extend"
require "zeitwerk"

# dev
require "pry"

module Kiba
  # kiba-tms application loading, configuration, and convenience methods
  #
  # == Explanation of the configuration and order of things in this file
  #
  # . {base_config} - Define default and basic project settings that
  #   need to be available in order for the rest of the application
  #   settings to be constructed and/or loaded
  # . {loader}
  module Tms
    ::Tms = Kiba::Tms

    module_function

    extend Dry::Configurable
    # For dev/debugging. Set to :verbose to have application print everything
    #   it does to screen
    Kiba::Extend.config.job_verbosity = :verbose
    setting :stdout_mode, default: Kiba::Extend.job_verbosity, reader: true

    def verbose?
      true if %i[verbose debug].include?(Tms.stdout_mode)
    end

    def debug?
      true if Tms.stdout_mode == :debug
    end

    def base_config
      setting :empty_table_list_path,
        default: "#{Gem.loaded_specs["kiba-tms"].full_gem_path}/"\
        "empty_tables.txt",
        reader: true
      setting :datadir,
        default: "#{Gem.loaded_specs["kiba-tms"].full_gem_path}/data",
        reader: true
      # Name of directory containing TMS tables in CSV format. Expected to be
      #   found in `:datadir`
      setting :tmsdir, default: "tms", reader: true
      setting :delim, default: Kiba::Extend.delim, reader: true
      setting :sgdelim, default: Kiba::Extend.sgdelim, reader: true
      setting :notedelim, default: "%CR%%CR%", reader: true
      setting :nullvalue, default: "%NULLVALUE%", reader: true
      # File registry - best to just leave this as-is
      setting :registry, default: Kiba::Extend.registry, reader: true
      # TMS tables not used in a given project. Override in project application
      #   These should be tables that are not literally empty. Empty tables are
      #   listed in the file found at Tms.empty_table_list_path
      setting :excluded_tables, default: [], reader: true
      setting :tms_table_dir_path,
        default: nil,
        reader: true,
        constructor: ->(_val) { File.join(datadir, tmsdir) }
      setting :blank_jobs, default: %i[], reader: true
    end

    def loader
      @loader ||= setup_loader
    end

    def setup_loader
      puts "LOADING KIBA-TMS" if Tms.verbose?
      base_config
      @loader = Zeitwerk::Loader.new
      #              @loader.log!
      @loader.push_dir(
        File.expand_path(__FILE__).delete_suffix(".rb"),
        namespace: Kiba::Tms
      )
      @loader.inflector.inflect(
        "classification_xrefs" => "ClassificationXRefs",
        "dd_contexts" => "DDContexts",
        "dd_languages" => "DDLanguages",
        "email_types" => "EMailTypes",
        "ref_xrefs" => "RefXRefs",
        "version" => "VERSION"
      )
      jobs = File.join(__dir__, "tms", "jobs")
      transforms = File.join(__dir__, "tms", "transforms")
      @loader.do_not_eager_load(jobs, transforms)
      @loader.enable_reloading
      @loader.setup
      @loader
    end
    private_class_method(:setup_loader)

    def reload!
      @loader.reload
    end

    setting :table_lookup,
      default: {
        "0" => "NO TABLE WITH THIS ID BUT IT IS SOMETIMES USED",
        "23" => "Constituents",
        "47" => "Exhibitions",
        "49" => "ExhObjXrefs",
        "50" => "ExhVenObjXrefs",
        "51" => "ExhVenuesXrefs",
        "79" => "LoanObjXrefs",
        "81" => "Loans",
        "83" => "Locations",
        "89" => "ObjAccession",
        "94" => "ObjComponents",
        "95" => "Conditions",
        "97" => "CondLineItems",
        "102" => "ObjDeaccession",
        "108" => "Objects",
        "116" => "ObjInsurance",
        "126" => "ObjRights",
        "143" => "ReferenceMaster",
        "187" => "HistEvents",
        "189" => "Sites",
        "287" => "TermMasterThes",
        "318" => "MediaMaster",
        "322" => "MediaRenditions",
        "345" => "Shipments",
        "355" => "ShipmentSteps",
        "461" => "InsurancePolicies",
        "631" => "AccessionLot",
        "632" => "RegistrationSets",
        "726" => "ObjContext",
        "790" => "Projects",
        "792" => "ConservationReports"
      },
      reader: true

    # Maps contexts from DDContexts to Tables. Currently used only for
    #   UserFields handling, so that UserFieldXrefs can be treated as
    #   MultiTableMergeable
    setting :context_to_table_mapping,
      default: {
        "Objects" => "Objects",
        "Object Rights" => "ObjRights"
      },
      reader: true
    # PROJECT SPECIFIC CONFIG
    setting :boolean_active_mapping,
      default: {"0" => "inactive", "1" => "active"},
      reader: true
    setting :cspace_profile, default: :fcart, reader: true

    # @return [Array<String>] CollectionSpace record types being populated in
    #   the migration. For objects and procedures, the form used must
    #   downcase to the form used in item1_type/item2_type fields in
    #   nonhierarchical relationships
    setting :cspace_target_records,
      default: %w[Acquisitions Collectionobjects Loansin Loansout
        Orgs Persons Places Works Valuationcontrols],
      reader: true
    setting :boolean_yn_mapping,
      default: {"0" => "n", "1" => "y"},
      reader: true
    setting :boolean_yes_no_mapping,
      default: {"0" => "no", "1" => "yes"},
      reader: true
    setting :inverted_boolean_yn_mapping,
      default: {"0" => "y", "1" => "n"},
      reader: true

    # @return [String] to use as currency value when none exists in the data
    setting :default_currency, default: "US Dollar", reader: true

    # Client-specific initial data cleaner, applied before processing
    setting :data_cleaner, default: nil, reader: true

    # Client-specific cleanup of whitespace, special characters, etc. to be
    #   generically applied before finalizing initial data prep jobs (or writing
    #   out final data for ingest)
    #
    # IMPLEMENTATION NOTE: Should take a `fields` parameter that defaults to
    #   `:all`, but can be given an array of specific field names
    setting :final_data_cleaner, default: nil, reader: true

    # if true, do not delete (not assigned) and (not entered) and other similar
    #   values from type lookup tables before merging in
    setting :migrate_no_value_types, default: false, reader: true

    # @return String ready to be converted into a Regexp
    #
    # If :migrate_no_value_types = false, type values matching any of these
    #   (case insensitive, wrapped in square brackets or parens) are removed
    #   from prepared lookups
    setting :no_value_type_pattern,
      default: [
        "enter your value here", "none assigned", "not assigned", "not defined",
        "not entered", "part of an object", "not specified"
      ],
      reader: true,
      constructor: proc { |value|
        alts = "(#{value.join("|")})"
        "(\\(|\\[)?#{alts}(\\)|\\])?$"
      }

    # Controls selected behavior of migration. Generally :dev will retain some
    #   data values that will be removed when this is set to :prod.
    #
    # - Names marked by client to be dropped from migration: When `dev`, these
    #   will be retained, but converted to `DROPPED FROM MIGRATION` so that any
    #   inadvertent effects of dropping the names may be caught. When `prod`,
    #   the names just won't be merged into any data
    # - If there are any supplied jobs registered by
    #   `RegistryData.register_sample_files`, the sample will be selected
    #   in the final `for_ingest` job for each target record type
    # - Some prep jobs will retain otherwise deleted rows if the status is
    #   :prelim. Can be used to create initial reports for decisions about
    #   migrating inactive values or not
    # Expected values: :prelim, :dev, :prod
    setting :migration_status, default: :dev, reader: true

    # Used to keep track of multi-table-merge work. Organized by target table.
    setting :table_merge_status, default: {}, reader: true

    # TMS-internal fields to be deleted
    setting :tms_fields,
      default: %i[loginid entereddate gsrowversion],
      reader: true
    setting :using_public_browser, default: false, reader: true

    setting :inventory_status_mapping,
      default: {},
      reader: true,
      constructor: ->(value) do
        value.merge(Tms::FlagLabels.mappings)
          .merge(Tms::ObjCompStatuses.mappings)
          .merge(Tms::ObjectStatuses.mappings)
      end
    setting :classifications, reader: true do
      # how to map/merge fields from Classifications table into objects
    end

    Error = Module.new
    UnconfiguredModuleError = Class.new(NameError) { include Error }
    UnknownObjLocTempTextMappingError = Class.new(StandardError) {
      include Error
    }
    UnknownAuthorityTypeCode = Class.new(StandardError) { include Error }

    def configs
      Kiba::Extend.project_configs
    end

    def finalize_config
      Tms::Utils::ConfiguredJobExtender.call
    end

    def meta_config
      Tms::Utils::ConRefTargetExtender.call
      used_multi_table_mergeable_configs.each do |mod|
        mod.define_for_table_modules
      end
      Tms::Utils::ForTableEmptyTypeCleanupExtender.call
      Tms::Utils::ForTableTypeCleanupExtender.call
      Tms::ThesXrefs.set_note_sources
    end

    def for_merge_into(tablename)
      Tms.configs.select do |config|
        config.respond_to?(:target_tables) &&
          config.target_tables.any?(tablename) &&
          config.respond_to?(:used?) &&
          config.used?
      end
    end

    def checkable_tables
      Tms.configs.select { |config| config.respond_to?(:checkable) }
    end

    # @return [Array<Module>]
    def used_multi_table_mergeable_configs
      Tms.configs.select do |config|
        config.is_a?(Tms::Mixins::MultiTableMergeable) &&
          config.respond_to?(:used?) &&
          config.used?
      end
    end

    def init_config(mod)
      result = Tms::Services::InitialConfigDeriver.call(mod: mod)
      result.output
    end

    def needed_work(mod)
      Tms::Services::NeededWorkChecker.call(mod)
    end

    # methods to delete after development is done

    # @param jobkey [Symbol]
    # @param column [Symbol] keycolumn on which to lookup
    def get_lookup(jobkey:, column:)
      return nil if Tms.blank_jobs.include?(jobkey)
      return nil unless job_output?(jobkey)

      Kiba::Extend::Utils::Lookup.csv_to_hash(
        file: Tms.registry.resolve(jobkey).path,
        keycolumn: column
      )
    end

    # @param jobkey [Symbol]
    def job_output?(jobkey)
      return false if Tms.blank_jobs.include?(jobkey)

      result = Kiba::Extend::Job.output?(jobkey)
      Tms.blank_jobs << jobkey unless result == true
      result
    end

    # @param jobkey [Symbol]
    # @return [Array<Symbol>]
    def headers_for(jobkey)
      path = Tms.registry.resolve(jobkey).path
      return [] unless File.exist?(path)

      `head -n 1 #{path}`.chomp
        .split(",")
        .map(&:to_sym)
    end
  end
end

Kiba::Tms.loader
Kiba::Extend.config.config_namespaces = [Kiba::Tms]
