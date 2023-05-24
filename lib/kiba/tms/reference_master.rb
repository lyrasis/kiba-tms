# frozen_string_literal: true

module Kiba
  module Tms
    module ReferenceMaster
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[alphaheading sortnumber publicaccess
          conservationentityid],
        reader: true
      extend Tms::Mixins::Tableable

      setting :con_ref_name_merge_rules,
        default: {
          fcart: {
            agent: {
              suffixes: %w[personlocal organizationlocal],
              merge_role: true,
              role_suffix: "role"
            },
            publisher: {
              suffixes: %w[organizationlocal],
              merge_role: false
            }
          }
        },
        reader: true
    end
  end
end
