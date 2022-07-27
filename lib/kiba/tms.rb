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

loader = Zeitwerk::Loader.new
loader.inflector.inflect(
  'classification_xrefs' => 'ClassificationXRefs'
)
loader.push_dir("#{__dir__}/tms", namespace: Kiba::Tms)
#loader.logger = method(:puts)
loader.setup


# Namespace for the overall project
module Kiba
  module Tms
    ::Tms = Kiba::Tms
    
    extend Dry::Configurable

    puts "LOADING KIBA-TMS"
    
    # you will want to override the following in any application using this extension
    setting :datadir, default: "#{__dir__}/data", reader: true
    setting :delim, default: Kiba::Extend.delim, reader: true
    setting :sgdelim, default: Kiba::Extend.sgdelim, reader: true
    # TMS tables not used in a given project. Override in project application
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
    # whether conservation entity data has actually been used/augmented (true) or whether it looks like the
    #   default field data had been populated automatically by TMS (false)
    setting :conservationentity_used, default: false, reader: true
    # if true, do not delete (not assigned) and (not entered) and other similar values from type lookup tables
    #   before merging in
    setting :migrate_no_value_types, default: false, reader: true

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

    setting :constituents, reader: true do
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
    setting :names, reader: true do
      setting :cleanup_iteration, default: 0, reader: true
      # whether to add "variant form" to name term flag field
      setting :flag_variant_form, default: false, reader: true
      setting :set_term_pref_for_lang, default: false, reader: true
      setting :set_term_source, default: false, reader: true
    end
    
    setting :name_cleanup0, reader: true do
      setting :multi_source_normalizer, default: Kiba::Extend::Utils::MultiSourceNormalizer.new, reader: true
    end
    
    setting :name_compilation, reader: true do
      setting :multi_source_normalizer, default: Kiba::Extend::Utils::MultiSourceNormalizer.new, reader: true
      # fields to delete from name compilation report
      setting :delete_fields, default: [], reader: true
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

    setting :text_entries, reader: true do
      # pass in client-specific transform classes to prepare text_entry rows for merging
      setting :for_object_transform, default: nil, reader: true
    end
  end
end


