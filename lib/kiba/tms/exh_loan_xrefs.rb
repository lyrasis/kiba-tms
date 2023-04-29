# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module ExhLoanXrefs
      extend Dry::Configurable
      module_function

      extend Tms::Mixins::Tableable
    end
  end
end
