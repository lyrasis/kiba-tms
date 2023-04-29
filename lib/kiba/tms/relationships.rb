# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module Relationships
      extend Dry::Configurable

      module_function

      setting :delete_fields,
        default: %i[movecolocated rel1prep rel2prep relation1plural
          relation2plural transitive],
        reader: true
      extend Tms::Mixins::Tableable

      # appears as though it should extend MultiTableMergeable, but this table
      #   gets merged into Associations or AssocParents, and those are the
      #   MultiTableMergeable tables.
    end
  end
end
