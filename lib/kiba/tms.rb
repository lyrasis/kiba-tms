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
    
    extend Dry::Configurable

    puts "LOADING KIBA-TMS"
    
    # you will want to override the following in any application using this extension
    setting :datadir, default: "#{__dir__}/data", reader: true
    setting :delim, default: Kiba::Extend.delim, reader: true
    # TMS tables not used in a given project. Override in project application
    setting :excluded_tables, default: [], reader: true
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
      # field to use as initial/preferred form
      setting :preferred_name_field, default: :displayname, reader: true
      # field to use as alt form
      setting :var_name_field, default: :alphasort, reader: true
      setting :include_flipped_as_variant, default: true, reader: true

      # map these boolean, coded fields to text note values?
      # IF a client wants these true, then you need to do work
      setting :map_approved, default: false, reader: true
      setting :map_active, default: false, reader: true
      setting :map_isstaff, default: false, reader: true
      setting :map_isprivate, default: false, reader: true

      # what cs field to map :culturegroup into
      setting :culturegroup_target, default: :group, reader: true

      # inactive addresses are excluded from migration
      setting :omit_inactive_address, default: false, reader: true
      # ConAddress columns to include in address value
      setting :address_fields,
        default: %i[displayname1 displayname2 streetline1 streetline2 streetline3 city state zipcode],
        reader: true
      # ConAddress columns that will be combined into CS addressplace1, if present
      setting :addressplace1_fields,
        default: %i[displayname1 displayname2],
        reader: true
      # ConAddress columns that will be combined into CS addressplace2.
      # If no values in addressplace1_fields, the first of these becomes addressplace1
      setting :addressplace2_fields,
        default: %i[streetline1 streetline2 streetline3],
        reader: true
      setting :addressplace1_delim, default: ' -- ', reader: true
      setting :addressplace2_delim, default: ', ', reader: true
      # The next four settings are whether to generate notes about address type/status, eg. "Is default mailing address"
      #   Default to no since CS doesn't have any note field associated with a given address
      setting :address_shipping, default: false, reader: true
      setting :address_billing, default: false, reader: true
      setting :address_mailing, default: false, reader: true
      setting :address_active, default: false, reader: true
      setting :address_dates, default: false, reader: true
      # What to do with address remarks:
      #  - :plain - will go into authority record's note field
      #  - :specific - will go into a note tagged with the specific address it applies to
      setting :address_remarks_handling, default: :specific, reader: true
      
      # The following are useful if there are duplicate preferred names that have different date values that
      #   can disambiguate the names
      setting :date_append, reader: true do
        # constituenttype values to add dates to. Should be: [:all], [:none], or Array of String values
        setting :to_types, default: [:all], reader: true
        # String that will separate the two dates. Will be appended to start date if there is no end date.
        #   Will be prepended to end date if there is no start date.
        setting :date_sep, default: ' - ', reader: true
        # String that will be inserted between name and prepared date value. Any punctuation that should open
        #   the wrapping of the date value should be included here.
        setting :name_date_sep, default: ', (', reader: true
        # String that will be appended to the end of result, closing the date value
        setting :date_suffix, default: ')', reader: true
      end
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
    
    setting :objects, reader: true do
      # client-specfic fields to delete
      setting :delete_fields, default: [], reader: true

      # default mapping will be skipped, fields will be left as-is in objects__prep job for handling
      #  in client project
      setting :custom_map_fields, default: [], reader: true

      # whether to map the given field
      setting :map, reader: true do
        setting :catalogueisodate, default: false, reader: true
        setting :cataloguer, default: false, reader: true
        setting :curator, default: false, reader: true
        setting :dateeffectiveisodate, default: false, reader: true
      end
    end

    setting :obj_context, reader: true do
      # client-specfic fields to delete
      setting :delete_fields, default: [], reader: true
    end

    setting :text_entries, reader: true do
      # pass in client-specific transform classes to prepare text_entry rows for merging
      setting :for_object_transform, default: nil, reader: true
    end

    TABLES = {
      '23'=>'Constituents',
      '47'=>'Exhibitions',
      '49'=>'ExhObjXrefs',
      '51'=>'ExhVenuesXrefs',
      '79'=>'LoanObjXrefs',
      '81'=>'Loans',
      '94'=>'ObjComponents',
      '95'=>'Conditions',
      '108'=>'Objects',
      '143'=>'ReferenceMaster',
      '287'=>'TermMasterThes'
    }
  end
end

loader = Zeitwerk::Loader.new
loader.inflector.inflect(
  'classification_xrefs' => 'ClassificationXRefs'
  )
loader.push_dir("#{__dir__}/tms", namespace: Kiba::Tms)
#loader.logger = method(:puts)
loader.setup

