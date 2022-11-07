# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ThesXrefs
      extend Dry::Configurable
      module_function

      setting :delete_fields,
        default: %i[removedloginid removeddate primarycnid],
        reader: true
      extend Tms::Mixins::Tableable
      extend Tms::Mixins::MultiTableMergeable
    end
  end
end
