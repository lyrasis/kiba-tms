# frozen_string_literal: true

module Kiba
  module Tms
    module Acquisitions
      extend Dry::Configurable

      setting :cs_record_id_field,
        default: :acquisitionreferencenumber,
        reader: true

      setting :cs_fields, default: {
                            fcart: %i[
                              acquisitionreferencenumber accessiondategroup
                              acquisitionauthorizer acquisitionauthorizerdate
                              acquisitiondategroup acquisitionmethod
                              acquisitionsourcepersonlocal
                              acquisitionsourceorganizationlocal ownerpersonlocal
                              ownerorganizationlocal transferoftitlenumber
                              grouppurchasepricecurrency grouppurchasepricevalue
                              objectofferpricecurrency objectofferpricevalue
                              objectpurchaseofferpricecurrency objectpurchaseofferpricevalue
                              objectpurchasepricecurrency objectpurchasepricevalue
                              originalobjectpurchasepricecurrency
                              originalobjectpurchasepricevalue acquisitionreason
                              approvalgroup approvalindividual approvalstatus approvaldate
                              approvalnote acquisitionnote acquisitionprovisos
                              acquisitionfundingcurrency acquisitionfundingvalue
                              acquisitionfundingsourcepersonlocal
                              acquisitionfundingsourceorganizationlocal
                              acquisitionfundingsourceprovisos creditline
                            ]
                          },
        reader: true
      extend Tms::Mixins::CsTargetable

      module_function
    end
  end
end
