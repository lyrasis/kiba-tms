# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ObjIncoming
      module_function
      
      extend Dry::Configurable
      # whether or not table is used
      setting :used, default: ->{ Tms::Tables::List.call.any?('ObjIncoming') }, reader: true
      # Fields beyond DeleteTmsFields general fields to delete
      setting :delete_fields, default: %i[], reader: true

      def all_fields
        %i[objincomingid objectid inpurpose requestedby requestdate approvedby approvaldate
           custodybegdate custodyenddate loanbegdate loanenddate displaybegdate displayenddate
           expectedindate expectedoutdate actualindate actualoutdate conservationdate
           shippingmethod shipper shippingestimate shippingactual shippingpaidby shipbilllading
           courierin courierout cratingestimate cratingactual cratepaidby
           ininsurvalue ininsurestimate ininsuractual ininsurpaidby
           depositortext depositordesignee makertext specialconditions remarks] - delete_fields
      end

      def content_fields
        fields = all_fields.dup
        fields - %i[objincomingid objectid]
      end
    end
  end
end
