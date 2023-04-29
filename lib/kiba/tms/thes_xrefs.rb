# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module ThesXrefs
      extend Dry::Configurable
      module_function

      setting :delete_fields,
        default: %i[removedloginid removeddate],
        reader: true
      extend Tms::Mixins::Tableable
      extend Tms::Mixins::MultiTableMergeable

      # As with ObjLocations, it appears that inactive here is a way to mark
      #   erroneous/accidental entries
      setting :drop_inactive, default: true, reader: true

      # pass in client-specific transform classes to prepare thes_xrefs rows for
      #   merging
      setting :for_loans_prepper, default: nil, reader: true

      # pass in client-specific transform classes to merge thes_xrefs rows into
      #   target tables
      setting :for_loans_merge, default: nil, reader: true

    end
  end
end
