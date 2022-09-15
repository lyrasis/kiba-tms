# frozen_string_literal: true

#require 'active_support'
#require 'active_support/core_ext/object'
#require 'dry-configurable'
#require 'kiba'
#require 'kiba-common/destinations/csv'
#require 'kiba-common/dsl_extensions/show_me'
#require 'kiba-common/sources/csv'
require 'kiba/extend'
require 'zeitwerk'

# dev
require 'pry'

# Namespace for the overall project
module Kiba
  module Tms
    ::Tms = Kiba::Tms
    module_function
    
    extend Dry::Configurable

    def loader
      @loader ||= setup_loader
    end

    private def setup_loader
              puts "LOADING KIBA-TMS"
              @loader = Zeitwerk::Loader.new
#              @loader.log!
              @loader.push_dir(File.expand_path(__FILE__).delete_suffix('.rb'), namespace: Kiba::Tms)
              @loader.inflector.inflect(
                'classification_xrefs' => 'ClassificationXRefs',
                'dd_languages' => 'DDLanguages',
                'version'   => 'VERSION'
              )
              @loader.enable_reloading
              @loader.setup
              @loader.eager_load
              @loader
            end

    def reload!
      @loader.reload
    end

    # you will want to override the following in any application using this extension
    setting :empty_table_list_path, default: "#{__dir__}/empty_tables.txt", reader: true
    setting :tms_table_dir_path, default: "#{__dir__}/data/tms", reader: true
    setting :datadir, default: "#{__dir__}/data", reader: true
    setting :delim, default: Kiba::Extend.delim, reader: true
    setting :sgdelim, default: Kiba::Extend.sgdelim, reader: true
    setting :nullvalue, default: '%NULLVALUE%', reader: true
    setting :table_lookup,
      default: {
        '23'=>'Constituents',
        '47'=>'Exhibitions',
        '49'=>'ExhObjXrefs',
        '51'=>'ExhVenuesXrefs',
        '79'=>'LoanObjXrefs',
        '81'=>'Loans',
        '89'=>'ObjAccession',
        '94'=>'ObjComponents',
        '95'=>'Conditions',
        '102'=>'ObjDeaccession',
        '108'=>'Objects',
        '126'=>'ObjRights',
        '143'=>'ReferenceMaster',
        '187'=>'HistEvents',
        '189'=>'Sites',
        '287'=>'TermMasterThes',
        '318'=>'MediaMaster',
        '322'=>'MediaRenditions',
        '345'=>'Shipments',
        '355'=>'ShipmentSteps',
        '631'=>'AccessionLot',
        '632'=>'RegistrationSets',
        '726'=>'ObjContext',
        '790'=>'Projects',
        '792'=>'ConservationReports'
      },
      reader: true

    # TMS tables not used in a given project. Override in project application
    #   These should be tables that are not literally empty. Empty tables are listed in the file found
    #   at Tms.empty_table_list_path
    setting :excluded_tables, default: [], reader: true
    # Different TMS installs may have slightly different table names. For instance EnvironmentalReqTypes (expected by
    #   this application) vs. EnvironmentalRequirementTypes (as found in another TMS instance). The Hash given as the
    #   following setting can be used to override table names:
    #
    # ```
    # { 
    setting :table_name_overrides, default: {}, reader: true

    # File registry - best to just leave this as-is
    setting :registry, default: Kiba::Extend.registry, reader: true

    # These weird, specific settings are included here instead of in individual job or transform code
    #   because it may be necessary to override them per client project using this library.
    setting :cspace_profile, default: :fcart, reader: true

    # client-specific cleanup of whitespace, special characters, etc. to be generically applied
    setting :data_cleaner, default: nil, reader: true

    # TMS-internal fields to be deleted
    setting :tms_fields, default: %i[loginid entereddate gsrowversion], reader: true
    
    # whether conservation entity data has actually been used/augmented (true) or whether it looks like the
    #   default field data had been populated automatically by TMS (false)
    setting :conservationentity_used, default: false, reader: true
    # if true, do not delete (not assigned) and (not entered) and other similar values from type lookup tables
    #   before merging in
    setting :migrate_no_value_types, default: false, reader: true
    setting :no_value_type_pattern,
      default: '^(\(|\[)?(enter your value here|none assigned|not assigned|not defined|not entered|part of an object|not specified)(\)|\])?$',
      reader: true

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
      setting :fieldmap,
        default: {
          classification: :classification,
          subclassification: :subclassification,
          subclassification2: :subclassification2,
          subclassification3: :subclassification3,
        },
        reader: true
    end

    setting :locations, reader: true do
      setting :cleanup_iteration, default: 0, reader: true
      # Whether client wants the migration to include construction of a location hierarchy
      setting :hierarchy, default: true, reader: true
      setting :hierarchy_delim, default: ' > ', reader: true
      # Which fields in obj_locations need to be concatenated with the location value to create additional
      #   location values (and thus need a unique id added to look them up)
      setting :fulllocid_fields, default: %i[locationid loclevel searchcontainer temptext shipmentid crateid sublevel], reader: true
      # which authority types to process records and hierarchies for (organizations used as locations are
      #   handled a bit separately
      setting :authorities, default: %i[local offsite], reader: true
      setting :multi_source_normalizer, default: Kiba::Extend::Utils::MultiSourceNormalizer.new, reader: true
    end

    setting :locations, reader: true do
      setting :cleanup_iteration, default: 0, reader: true
      # Whether client wants the migration to include construction of a location hierarchy
      setting :hierarchy, default: true, reader: true
      setting :hierarchy_delim, default: ' > ', reader: true
      # Which fields in obj_locations need to be concatenated with the location value to create additional
      #   location values (and thus need a unique id added to look them up)
      setting :fulllocid_fields, default: %i[locationid loclevel searchcontainer temptext shipmentid crateid sublevel], reader: true
      # which authority types to process records and hierarchies for (organizations used as locations are
      #   handled a bit separately
      setting :authorities, default: %i[local offsite], reader: true
      setting :multi_source_normalizer, default: Kiba::Extend::Utils::MultiSourceNormalizer.new, reader: true
    end
    
    setting :obj_context, reader: true do
      # client-specfic fields to delete
      setting :delete_fields, default: [], reader: true
    end
    
    def configs
      Tms.constants.select do |constant|
        evaled = Tms.const_get(constant)
        evaled.is_a?(Module) && evaled.respond_to?(:config)
      end.map{ |const| Tms.const_get(const) }
    end

    def init_config(mod)
      Tms::Services::InitialConfigDeriver.call(mod).each{ |config| puts config.value! }
    end
  end
end


