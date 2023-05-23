# frozen_string_literal: true

module Kiba
  module Tms
    module MediaRenditions
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[parentrendid sortnumber mediasizeid thumbextensionid
          thumbblobsize loctermid quantitymade quantityavailable],
        reader: true
      extend Tms::Mixins::Tableable

      setting :con_ref_name_merge_rules,
        default: {
          fcart: {
            contributor: {
              suffixes: %w[personlocal organizationlocal],
              merge_role: false,
              role_suffix: nil
            },
            creator: {
              suffixes: %w[personlocal organizationlocal],
              merge_role: false,
              role_suffix: nil
            },
            publisher: {
              suffixes: %w[personlocal organizationlocal],
              merge_role: false,
              role_suffix: nil
            },
            rightsholder: {
              suffixes: %w[personlocal organizationlocal],
              merge_role: false,
              role_suffix: nil
            }
          }
        },
        reader: true
    end
  end
end
