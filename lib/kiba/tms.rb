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
    extend Dry::Configurable

    puts "LOADING KIBA-TMS"
    
    # you will want to override the following in any application using this extension
    setting :datadir, default: "#{__dir__}/data", reader: true
    setting :delim, default: Kiba::Extend.delim, reader: true
    # TMS tables not used in a given project. Override in project application
    setting :excluded_tables, default: [], reader: true
    # File registry - best to just leave this as-is
    setting :registry, default: Kiba::Extend.registry, reader: true

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

::Tms = Kiba::Tms

