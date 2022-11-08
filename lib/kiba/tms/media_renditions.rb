# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module MediaRenditions
      extend Dry::Configurable
      module_function

      setting :delete_fields,
        default: %i[parentrendid sortnumber mediasizeid thumbextensionid
                    thumbblobsize loctermid quantitymade quantityavailable],
        reader: true
      extend Tms::Mixins::Tableable

      setting :con_ref_field_rules,
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
