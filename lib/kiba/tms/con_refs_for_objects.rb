# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ConRefsForObjects
      extend Dry::Configurable
      module_function

      setting :source_job_key, default: :con_refs_for__objects, reader: true
      setting :delete_fields, default:[], reader: true
      setting :empty_fields, default: {}, reader: true
      extend Tms::Mixins::Tableable

      # @return [Array<String>] role values not included in
      #   Objects.con_role_treatment_mappings, that should NOT be reported
      #   as unmapped roles
      setting :ignored_roles, default: [], reader: true
      setting :known_roles, default: [], reader: true
      setting :unmapped_roles, default: [], reader: true
      setting :configurable, default: {
        known_roles: proc{ set_known_roles }
      },
        reader: true

      def set_known_roles
        return [] unless Tms::ConRefs.for?('Objects')

        Tms::Data::Column.new(mod: self, field: :role)
          .unique_values
      end
    end
  end
end
