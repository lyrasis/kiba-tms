# frozen_string_literal: true

require "dry-configurable"

module Kiba
  module Tms
    module Loans
      extend Dry::Configurable

      module_function

      # @return [Array<Symbol>] unmigratable fields removed by default
      setting :delete_fields,
        default: %i[sortnumber mnemonic isforeignlender
          hasspecialrequirements],
        reader: true,
        constructor: proc { |value|
          value << :primaryconxrefid if con_link_field == :primaryconxrefid
        }
      extend Tms::Mixins::Tableable

      setting :name_fields,
        default: %i[approvedby contact requestedby],
        reader: true
      extend Tms::Mixins::UncontrolledNameCompileable

      # Some TMS installs use :constituentidold, which is a direct constituent
      #   table lookup and must be merged in differently
      #
      # If :primaryconxrefid, this should be ignored and ConXrefDetails used to
      #   merge in all names, not just a primary name
      setting :con_link_field, default: :primaryconxrefid, reader: true

      setting :record_num_merge_config,
        default: {
          sourcejob: :tms__loans,
          numberfield: :loannumber
        }, reader: true

      # Defines how auto-generated config settings are populated
      setting :configurable,
        default: {
          con_link_field: proc {
            Tms::Services::Loans::ConLinkFieldDeriver.call
          }
        },
        reader: true
    end
  end
end
