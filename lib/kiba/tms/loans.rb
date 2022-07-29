# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module Loans
      extend Dry::Configurable
      module_function
      
      # whether or not table is used
      setting :used, default: ->{ Tms.excluded_tables.none?('Loans') }, reader: true
      # Fields beyond DeleteTmsFields general fields to delete
      setting :delete_fields, default: %i[sortnumber mnemonic isforeignlender hasspecialrequirements], reader: true
      setting :empty_fields, default: %i[], reader: true
      # Some TMS installs use :constituentidold, which is a direct constituent table lookup and must be merged in
      #   differently
      setting :con_link_field, default: :primaryconxrefid, reader: true
      def omitted_fields
        ( delete_fields + empty_fields ).uniq
      end
    end
  end
end
