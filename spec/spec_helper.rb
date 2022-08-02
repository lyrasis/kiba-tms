# frozen_string_literal: true

require 'bundler/setup'
require_relative '../lib/kiba/tms'
require 'dry/configurable/test_interface'

Tms.loader

module Tms
  module Constituents
    enable_test_interface
  end
end

# pulls in kiba-extend's helpers.rb, which lets you use existing methods for setting up and running
#   transform tests
require 'kiba/extend'
kiba_spec_dir = "#{Gem.loaded_specs['kiba-extend'].full_gem_path}/spec"
  Dir.glob("#{kiba_spec_dir}/*").sort.select{ |path| path.match?(/helpers\.rb$/) }.each do |rbfile|
  require rbfile
end


RSpec.configure do |config|
  config.extend Kiba::Tms
  config.include Helpers
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
