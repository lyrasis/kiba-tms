# frozen_string_literal: true

module Kiba
  module Tms
    module ExhVenuesXrefs
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[mnemonic venueconxrefid],
        reader: true
      setting :empty_fields,
        default: {
          exhvenuetitleid: [nil, "", "0", "-1"]
        },
        reader: true
      extend Tms::Mixins::Tableable

      setting :con_ref_name_merge_rules,
        default: {
          fcart: {
            venue: {
              suffixes: %w[person org],
              merge_role: false
            }
          }
        },
        reader: true
    end
  end
end
