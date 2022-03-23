# frozen_string_literal: true

require 'active_support'
require 'active_support/core_ext/object'
require 'dry-configurable'
require 'kiba'
require 'kiba-common/destinations/csv'
require 'kiba-common/dsl_extensions/show_me'
require 'kiba-common/sources/csv'
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
    setting :constituents, reader: true do
      # field to use as initial/preferred form
      setting :preferred_name_field, default: :displayname, reader: true
      # field to use as alt form
      setting :alt_name_field, default: :alphasort, reader: true

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

    setting :name_compilation, reader: true do
      setting :multi_source_normalizer, default: Kiba::Extend::Utils::MultiSourceNormalizer.new, reader: true
    end

    setting :locations, reader: true do
      setting :hierarchy_delim, default: ' >> ', reader: true
    end

    TABLES = {
      '23'=>'Constituents',
      '47'=>'Exhibitions',
      '51'=>'ExhVenuesXrefs',
      '81'=>'Loans',
      '108'=>'Objects',
      '143'=>'ReferenceMaster'
    }
  end
end

loader = Zeitwerk::Loader.new
loader.push_dir("#{__dir__}/tms", namespace: Kiba::Tms)
#loader.logger = method(:puts)
loader.setup

