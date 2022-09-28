# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module Relationships
      extend Dry::Configurable
      module_function

      setting :delete_fields,
        default: %i[movecolocated rel1prep rel2prep relation1plural relation2plural transitive],
        reader: true
      extend Tms::Mixins::Tableable

      extend Tms::Mixins::MultiTableMergeable

      # to support automated notification if new relationships exist in updated data
      setting :defined_rels, default: [], reader: true

      setting :configurable,
        default: {
          defined_rels: Proc.new{ set_defined_rels }
        },
        reader: true

      def set_defined_rels
        Tms::Services::Relationships::DefinedRelGetter.call
      end
    end
  end
end
