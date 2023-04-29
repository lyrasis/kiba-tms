# frozen_string_literal: true

# require 'active_support'
# require 'active_support/core_ext/object'
# require 'dry-configurable'
# require 'kiba'
# require 'kiba-common/destinations/csv'
# require 'kiba-common/dsl_extensions/show_me'
# require 'kiba-common/sources/csv'
require "kiba/extend"
require "zeitwerk"

# dev
require "pry"

# Namespace for the overall project
module Kiba
  module Tms
    ::Tms = Kiba::Tms

    module_function

    def loader
      @loader ||= setup_loader
    end

    def setup_loader
      puts "LOADING KIBA-TMS"
      @loader = Zeitwerk::Loader.new
      #              @loader.log!
      @loader.push_dir(
        File.expand_path(__FILE__).delete_suffix(".rb"),
        namespace: Kiba::Tms
      )
      @loader.inflector.inflect(
        "classification_xrefs" => "ClassificationXRefs",
        "dd_languages" => "DDLanguages",
        "email_types" => "EMailTypes",
        "ref_xrefs" => "RefXRefs",
        "version" => "VERSION"
      )
      @loader.enable_reloading
      @loader.setup
      @loader.eager_load
      @loader
    end
    private_class_method(:setup_loader)

    def reload!
      @loader.reload
    end

    extend Dry::Configurable
    def base_config
      # you will want to override the following in any application using this
      # extension
      setting :empty_table_list_path,
        default: "#{__dir__}/empty_tables.txt",
        reader: true
      setting :tms_table_dir_path,
        default: __dir__,
        reader: true,
        constructor: proc { |value|
          if value["kiba-tms/lib"]
            base = value.split("/")
            2.times { base.pop }
            dir = base.join("/")
            File.join(dir, "data", "tms")
          else
            value
          end
        }
      setting :datadir, default: "#{__dir__}/data", reader: true
      setting :delim, default: Kiba::Extend.delim, reader: true
      setting :sgdelim, default: Kiba::Extend.sgdelim, reader: true
      setting :nullvalue, default: "%NULLVALUE%", reader: true
      # File registry - best to just leave this as-is
      setting :registry, default: Kiba::Extend.registry, reader: true
      # TMS tables not used in a given project. Override in project application
      #   These should be tables that are not literally empty. Empty tables are
      #   listed in the file found at Tms.empty_table_list_path
      setting :excluded_tables, default: [], reader: true
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
        "631" => "AccessionLot",
        "632" => "RegistrationSets",
        "726" => "ObjContext",
        "790" => "Projects",
        "792" => "ConservationReports"
      },
      reader: true

    # PROJECT SPECIFIC CONFIG
    setting :boolean_active_mapping,
      default: {"0" => "inactive", "1" => "active"},
      reader: true
    setting :cspace_profile, default: :fcart, reader: true
    setting :boolean_yn_mapping, default: {"0" => "n", "1" => "y"}, reader: true
    # client-specific initial data cleaner, applied before processing
    setting :data_cleaner, default: nil, reader: true
    # TMS-internal fields to be deleted
    # client-specific cleanup of whitespace, special characters, etc. to be
    #   generically applied before finalizing initial data prep jobs (or writing
    #   out final data for ingest)
    setting :final_data_cleaner, default: nil, reader: true
    setting :inverted_boolean_yn_mapping,
      default: {"0" => "y", "1" => "n"},
      reader: true
    # if true, do not delete (not assigned) and (not entered) and other similar
    #   values from type lookup tables before merging in
    setting :migrate_no_value_types, default: false, reader: true
    # Controls selected behavior of migration. Generally :dev will retain some
    #   data values that will be removed when this is set to :prod.
    #
    # - Names marked by client to be dropped from migration: When `dev`, these
    #   will be retained, but converted to `DROPPED FROM MIGRATION` so that any
    #   inadvertent effects of dropping the names may be caught. When `prod`,
    #   the names just won't be merged into any data
    # Expected values: :dev, :prod
    setting :migration_status, default: :dev, reader: true
    # Used to keep track of multi-table-merge work. Organized by target table.
    setting :table_merge_status, default: {}, reader: true
    setting :tms_fields,
      default: %i[loginid entereddate gsrowversion],
      reader: true
    setting :using_public_browser, default: false, reader: true
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
      Tms.constants.select do |constant|
        evaled = Tms.const_get(constant)
        evaled.is_a?(Module) && evaled.respond_to?(:config)
      end.map { |const| Tms.const_get(const) }
    end

    def finalize_config
      Tms::Utils::ConfiguredJobExtender.call
    end

    def meta_config
      Tms::Utils::ConRefTargetExtender.call
      Tms::NameCompile.register_uncontrolled_name_compile_jobs
      # Tms::NameTypeCleanup.register_uncontrolled_ntc_jobs
      per_job_tables.each do |srctable|
        srctable.target_tables.each do |target|
          srctable.define_for_table_module(target)
        end
      end
    end

    def for_merge_into(tablename)
      Tms.configs.select do |config|
        config.respond_to?(:target_tables) &&
          config.target_tables.any?(tablename)
      end
    end

    def checkable_tables
      Tms.configs.select { |config| config.respond_to?(:checkable) }
    end

    def per_job_tables
      Tms.configs.select do |config|
        config.respond_to?(:target_tables) &&
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
    def needconfig
      configs.reject { |c| c.respond_to?(:used?) }
    end

    # @param jobkey [Symbol]
    # @param column [Symbol] keycolumn on which to lookup
    def get_lookup(jobkey:, column:)
      reg = Tms.registry.resolve(jobkey)
      path = reg.path
      unless File.exist?(path)
        Kiba::Extend::Command::Run.job(jobkey)
      end
      Kiba::Extend::Utils::Lookup.csv_to_hash(
        file: path,
        keycolumn: column
      )
    end

    # @param jobkey [Symbol]
    def job_output?(jobkey)
      reg = Tms.registry.resolve(jobkey)
      return false unless reg
      return true if File.exist?(reg.path)

      res = Kiba::Extend::Command::Run.job(jobkey)
      return false unless res

      !(res.outrows == 0)
    end
  end
end
