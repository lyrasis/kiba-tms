# frozen_string_literal: true

require 'amazing_print'
require 'dry-configurable'
require 'kiba'
require 'kiba-common/sources/csv'
require 'kiba-common/destinations/csv'
require 'kiba-common/dsl_extensions/show_me'
require 'kiba/extend'
require 'active_support'
require 'active_support/core_ext/object'

# dev
require 'pry'

require_relative 'tms/util'
require_relative 'tms/registry_data'

# Namespace for the overall project
module Kiba
  module Tms
    extend Dry::Configurable

    # Require all application files
    Dir.glob("#{__dir__}/kiba/tms/**/*").sort.select{ |path| path.match?(/\.rb$/) }.each do |rbfile|
      require_relative rbfile.delete_prefix("#{File.expand_path(__dir__)}/").delete_suffix('.rb')
    end

    # you will want to override this in any application using this extension
    setting :datadir, default: "#{__dir__}/data", reader: true
    # File registry - best to just leave this as-is
    setting :registry, default: Kiba::Extend.registry, reader: true
    
    Kiba::Tms::RegistryData.register

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
