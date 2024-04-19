# frozen_string_literal: true

module Kiba
  module Tms
    # == Date fields in this record type
    #
    # Exit section
    #
    # * exitdategroup (structured)
    #
    # Deaccession and disposal section
    #
    # * authorizationdate
    # * deaccessiondate
    # * disposaldate
    # * deaccessionapprovaldate (pair with deaccessionapprovalstatus)
    module Objectexit
      extend Dry::Configurable

      module_function

      setting :cs_record_id_field,
        default: :exitnumber,
        reader: true

      setting :cs_fields,
        default: {
          fcart:
          %i[exitnumber exitdategroup exitreason exitmethod
            exitquantity currentownerpersonlocal
            currentownerorganizationlocal depositorpersonlocal
            depositororganizationlocal exitnote packingnote
            displosalnewobjectnumber deaccessionauthorizer
            authorizationdate deaccessionapprovalgroup
            deaccessionapprovalindividual deaccessionapprovalstatus
            deaccessionapprovaldate deaccessionapprovalnote
            deaccessiondate disposaldate disposalmethod displosalreason
            disposalproposedrecipientpersonlocal
            disposalproposedrecipientorganizationlocal
            disposalrecipientpersonlocal
            disposalrecipientorganizationlocal disposalcurrency
            displosalvalue groupdisposalcurrency groupdisplosalvalue
            displosalprovisos displosalnote]
        },
        reader: true
      extend Tms::Mixins::CsTargetable
    end
  end
end
