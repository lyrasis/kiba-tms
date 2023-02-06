# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module Exhibitions
      extend Dry::Configurable
      module_function

      setting :delete_fields,
        default: %i[exhmnemonic nextdexid exhibitiontitleid
                   beginyear endyear displaydate],
        reader: true
      extend Tms::Mixins::Tableable

      setting :con_ref_name_merge_rules,
        default: {
          fcart: {
            exhibitionperson: {
              suffixes: %w[personlocal organizationlocal],
              merge_role: true,
              role_suffix: 'role'
            }
          }
        },
        reader: true
    end
  end
end
