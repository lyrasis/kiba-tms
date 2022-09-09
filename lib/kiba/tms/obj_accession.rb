# frozen_string_literal: true

require 'dry-configurable'

module Kiba
  module Tms
    module ObjAccession
      extend Dry::Configurable
      extend Tms::Omittable
      # whether or not table is used
      setting :used, default: ->{ Tms::Table::List.include?('ObjAccession') }, reader: true
      setting :fields,
        default: %i[accessionisodate accessionmethodid accessionminutes1 accessionminutes2 accessionvalue
                    acqjustification acquisitionlot acquisitionlotid acquisitionnumber acquisitionterms
                    approvalisodate1 approvalisodate2 authdate authorizer budget capitalprogram
                    currencyamount currencyid currencyrate currententityid currpercentownership
                    deedofgiftreceivediso deedofgiftsentiso initdate initiator localamount lotobjectnumber
                    objectid objectvalueid originalentityid registrationsetid remarks source suggestedaccvalue
                    suggestedvalueisodate valuationnotes],
        reader: true
      # Fields beyond DeleteTmsFields general fields to delete
      #   The first three rows are fields all marked as not in use in the TMS data dictionary
      setting :delete_fields,
        default: %i[currencyamount currencyrate localamount
                    accessionminutes1 accessionminutes2 budget capitalprogram
                    currencyid originalentityid currententityid],
        reader: true
      setting :empty_fields, default: %i[], reader: true
      # approaches required for creation of CS acquisitions and obj/acq relations
      #   options: :onetone, :lotnumber, :linkedlot
      #   see: https://github.com/lyrasis/kiba-tms/blob/main/doc/data_preparation_details/acquisitions.adoc
      setting :processing_approaches, default: %i[:onetoone], reader: true
    end
  end
end
