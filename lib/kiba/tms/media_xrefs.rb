# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module MediaXrefs
      extend Dry::Configurable
      module_function

      extend Tms::Mixins::Tableable
      extend Tms::Mixins::MultiTableMergeable

      setting :for_loans_prepper,
        default: Tms::Transforms::MediaXrefs::ForLoans,
        reader: true
    end
  end
end
