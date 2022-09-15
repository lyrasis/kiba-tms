# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module Loans
      extend Dry::Configurable
     extend Tms::Mixins::Tableable
      module_function

      setting :configurable,
        default: {
          con_link_field: Proc.new{ set_con_link_field }
        },
        reader: true
      setting :delete_fields, default: %i[sortnumber mnemonic isforeignlender hasspecialrequirements], reader: true
      setting :empty_fields, default: {}, reader: true
      # Some TMS installs use :constituentidold, which is a direct constituent table lookup and must be merged in
      #   differently
      # If :primaryconxrefid, this should be ignored and ConXrefDetails used to merge in all names, not
      #   just a primary name
      setting :con_link_field, default: :primaryconxrefid, reader: true

      def set_con_link_field
        af = all_fields
        return :primaryconxrefid if af.any?(:primaryconxrefid)
        return :constituentidold if af.any?(:constituentidold)

        :UNDETERMINED_ENTER_MANUALLY
      end
    end
  end
end
